import CryptoKit
import Foundation

struct DuplicateFile: Identifiable, Sendable {
  let url: URL
  let bytes: Int64
  let modifiedAt: Date?

  var id: String { url.path }
}

struct DuplicateGroup: Identifiable, Sendable {
  let id: String
  let bytesPerFile: Int64
  let files: [DuplicateFile]

  var reclaimableBytes: Int64 { bytesPerFile * Int64(max(0, files.count - 1)) }
  var hasDifferentNames: Bool {
    Set(files.map { $0.url.lastPathComponent.lowercased() }).count > 1
  }
}

struct NameSimilarityWarning: Identifiable, Sendable {
  let first: DuplicateFile
  let second: DuplicateFile
  let similarity: Double

  var id: String { [first.url.path, second.url.path].sorted().joined(separator: "|") }
}

struct DuplicateSnapshot: Sendable {
  let rootURL: URL
  let groups: [DuplicateGroup]
  let candidateCount: Int
  let hashedCount: Int
  let inaccessibleCount: Int
  let nameWarnings: [NameSimilarityWarning]

  var reclaimableBytes: Int64 { groups.reduce(0) { $0 + $1.reclaimableBytes } }
}

struct TrashResult: Sendable {
  let movedCount: Int
  let movedBytes: Int64
  let errors: [String]
  let reportURL: URL?
}

struct DuplicateScanner: Sendable {
  private struct Candidate {
    let url: URL
    let bytes: Int64
    let modifiedAt: Date?
  }

  func scan(rootURL: URL, minimumBytes: Int64 = 1_024 * 1_024) throws -> DuplicateSnapshot {
    let manager = FileManager()
    let root = rootURL.resolvingSymlinksInPath().standardizedFileURL
    let keys: Set<URLResourceKey> = [
      .isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey,
      .contentModificationDateKey,
    ]
    var inaccessible = 0
    guard
      let enumerator = manager.enumerator(
        at: root,
        includingPropertiesForKeys: Array(keys),
        options: [.skipsPackageDescendants],
        errorHandler: { _, _ in
          inaccessible += 1
          return true
        }
      )
    else { throw CocoaError(.fileReadUnknown) }

    var bySize: [Int64: [Candidate]] = [:]
    var candidateCount = 0
    for case let fileURL as URL in enumerator {
      if Task.isCancelled { throw CancellationError() }
      guard let values = try? fileURL.resourceValues(forKeys: keys) else { continue }
      if values.isDirectory == true, shouldSkipDirectory(fileURL) {
        enumerator.skipDescendants()
        continue
      }
      guard
        values.isRegularFile == true,
        values.isSymbolicLink != true
      else { continue }
      let bytes = Int64(values.fileSize ?? 0)
      guard bytes >= minimumBytes else { continue }
      candidateCount += 1
      bySize[bytes, default: []].append(
        Candidate(
          url: fileURL.standardizedFileURL, bytes: bytes, modifiedAt: values.contentModificationDate
        )
      )
    }

    var byDigest: [String: [Candidate]] = [:]
    var hashedCount = 0
    for candidates in bySize.values where candidates.count > 1 {
      for candidate in candidates {
        if Task.isCancelled { throw CancellationError() }
        guard let digest = try? sha256(of: candidate.url) else {
          inaccessible += 1
          continue
        }
        hashedCount += 1
        byDigest["\(candidate.bytes):\(digest)", default: []].append(candidate)
      }
    }

    let groups = byDigest.compactMap { digest, candidates -> DuplicateGroup? in
      guard candidates.count > 1, let size = candidates.first?.bytes else { return nil }
      let files = candidates.map {
        DuplicateFile(url: $0.url, bytes: $0.bytes, modifiedAt: $0.modifiedAt)
      }.sorted {
        ($0.modifiedAt ?? .distantPast) > ($1.modifiedAt ?? .distantPast)
      }
      return DuplicateGroup(id: digest, bytesPerFile: size, files: files)
    }.sorted { $0.reclaimableBytes > $1.reclaimableBytes }

    let digestByPath = Dictionary(
      uniqueKeysWithValues: byDigest.flatMap { digest, candidates in
        candidates.map { ($0.url.path, digest) }
      })
    let nameWarnings = findNameWarnings(
      candidates: bySize.values.flatMap { $0 },
      digestByPath: digestByPath
    )

    return DuplicateSnapshot(
      rootURL: root,
      groups: groups,
      candidateCount: candidateCount,
      hashedCount: hashedCount,
      inaccessibleCount: inaccessible,
      nameWarnings: nameWarnings
    )
  }

  func moveToTrash(
    files: [DuplicateFile],
    retainedOriginalByPath: [String: String],
    within rootURL: URL
  ) -> TrashResult {
    let manager = FileManager()
    let root = rootURL.resolvingSymlinksInPath().standardizedFileURL
    let rootPath = root.path.hasSuffix("/") ? root.path : root.path + "/"
    var count = 0
    var bytes: Int64 = 0
    var errors: [String] = []
    var movedRecords: [(original: String, duplicate: String)] = []

    for file in files {
      let candidate = file.url.resolvingSymlinksInPath().standardizedFileURL
      guard candidate.path.hasPrefix(rootPath), candidate.path != root.path else {
        errors.append("\(file.url.lastPathComponent): đường dẫn không an toàn")
        continue
      }
      guard let originalPath = retainedOriginalByPath[file.url.path] else {
        errors.append("\(file.url.lastPathComponent): không xác định được bản giữ lại")
        continue
      }
      let original = URL(fileURLWithPath: originalPath).resolvingSymlinksInPath()
        .standardizedFileURL
      guard original.path.hasPrefix(rootPath),
        manager.fileExists(atPath: original.path),
        let originalHash = try? sha256(of: original),
        let candidateHash = try? sha256(of: candidate),
        originalHash == candidateHash
      else {
        errors.append("\(file.url.lastPathComponent): nội dung đã thay đổi, thao tác bị hủy")
        continue
      }
      do {
        try manager.trashItem(at: candidate, resultingItemURL: nil)
        count += 1
        bytes += file.bytes
        movedRecords.append((original.path, file.url.path))
      } catch {
        errors.append("\(file.url.lastPathComponent): \(error.localizedDescription)")
      }
    }
    let reportURL: URL?
    do {
      reportURL = try writeReport(records: movedRecords, rootURL: root, movedBytes: bytes)
    } catch {
      errors.append("Không thể ghi báo cáo: \(error.localizedDescription)")
      reportURL = nil
    }
    return TrashResult(movedCount: count, movedBytes: bytes, errors: errors, reportURL: reportURL)
  }

  private func sha256(of url: URL) throws -> String {
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }
    var hasher = SHA256()
    while true {
      let data = try handle.read(upToCount: 1_024 * 1_024) ?? Data()
      if data.isEmpty { break }
      hasher.update(data: data)
      if Task.isCancelled { throw CancellationError() }
    }
    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
  }

  private func shouldSkipDirectory(_ url: URL) -> Bool {
    let path = url.path
    return url.lastPathComponent == ".Trash"
      || path.contains("/Library/Caches/")
      || path.hasSuffix("/Library/Caches")
  }

  private func findNameWarnings(
    candidates: [Candidate],
    digestByPath: [String: String]
  ) -> [NameSimilarityWarning] {
    var pairs: [(Candidate, Candidate)] = []
    var seen: Set<String> = []

    func appendPair(_ first: Candidate, _ second: Candidate) {
      let id = [first.url.path, second.url.path].sorted().joined(separator: "|")
      guard !seen.contains(id), contentDiffers(first, second, digestByPath: digestByPath) else {
        return
      }
      seen.insert(id)
      pairs.append((first, second))
    }

    let canonicalGroups = Dictionary(grouping: candidates) { candidate in
      candidate.url.pathExtension.lowercased() + ":" + canonicalStem(candidate.url)
    }
    for group in canonicalGroups.values where group.count > 1 {
      for candidate in group.dropFirst() { appendPair(group[0], candidate) }
    }

    let folderGroups = Dictionary(grouping: candidates) { candidate in
      candidate.url.deletingLastPathComponent().path + ":"
        + candidate.url.pathExtension.lowercased()
    }
    for group in folderGroups.values {
      let sorted = group.sorted { normalizedStem($0.url) < normalizedStem($1.url) }
      guard sorted.count > 1 else { continue }
      for index in 1..<sorted.count {
        let first = sorted[index - 1]
        let second = sorted[index]
        let score = nameSimilarity(first.url, second.url)
        if score >= 0.88 { appendPair(first, second) }
      }
    }

    return pairs.prefix(150).map { first, second in
      NameSimilarityWarning(
        first: DuplicateFile(url: first.url, bytes: first.bytes, modifiedAt: first.modifiedAt),
        second: DuplicateFile(url: second.url, bytes: second.bytes, modifiedAt: second.modifiedAt),
        similarity: nameSimilarity(first.url, second.url)
      )
    }.sorted { $0.similarity > $1.similarity }
  }

  private func contentDiffers(
    _ first: Candidate,
    _ second: Candidate,
    digestByPath: [String: String]
  ) -> Bool {
    if first.bytes != second.bytes { return true }
    guard let firstDigest = digestByPath[first.url.path],
      let secondDigest = digestByPath[second.url.path]
    else { return false }
    return firstDigest != secondDigest
  }

  private func canonicalStem(_ url: URL) -> String {
    normalizedStem(url).replacingOccurrences(
      of: #"[\s._-]*(copy|duplicate|final|old|new|ban sao|[0-9]+)$"#,
      with: "",
      options: [.regularExpression]
    )
  }

  private func normalizedStem(_ url: URL) -> String {
    url.deletingPathExtension().lastPathComponent
      .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
      .lowercased()
      .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: [.regularExpression])
      .trimmingCharacters(in: .whitespaces)
  }

  private func nameSimilarity(_ first: URL, _ second: URL) -> Double {
    let lhs = Array(normalizedStem(first))
    let rhs = Array(normalizedStem(second))
    guard !lhs.isEmpty || !rhs.isEmpty else { return 1 }
    var previous = Array(0...rhs.count)
    for (i, left) in lhs.enumerated() {
      var current = [i + 1] + Array(repeating: 0, count: rhs.count)
      for (j, right) in rhs.enumerated() {
        current[j + 1] = min(
          current[j] + 1,
          previous[j + 1] + 1,
          previous[j] + (left == right ? 0 : 1)
        )
      }
      previous = current
    }
    return 1 - Double(previous[rhs.count]) / Double(max(lhs.count, rhs.count))
  }

  private func writeReport(
    records: [(original: String, duplicate: String)],
    rootURL: URL,
    movedBytes: Int64
  ) throws -> URL? {
    guard !records.isEmpty else { return nil }
    let manager = FileManager()
    let reports = AppMetadata.applicationSupportDirectory().appendingPathComponent(
      "Reports", isDirectory: true)
    try manager.createDirectory(at: reports, withIntermediateDirectories: true)

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let reportURL = reports.appendingPathComponent(
      "duplicates_\(formatter.string(from: Date())).txt")
    var lines = [
      "BÁO CÁO TỆP TRÙNG LẶP — DISKORA",
      "Thời gian: \(Date().formatted(date: .numeric, time: .standard))",
      "Vị trí quét: \(rootURL.path)",
      "Đã chuyển vào Trash: \(records.count) tệp — \(ByteCount.string(movedBytes))",
      String(repeating: "-", count: 72),
    ]
    for record in records {
      lines.append("Bản giữ lại: \(record.original)")
      lines.append("Đã chuyển:   \(record.duplicate)")
      lines.append(String(repeating: "-", count: 40))
    }
    try lines.joined(separator: "\n").write(to: reportURL, atomically: true, encoding: .utf8)
    return reportURL
  }
}
