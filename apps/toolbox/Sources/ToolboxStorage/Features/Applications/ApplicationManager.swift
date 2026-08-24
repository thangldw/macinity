import AppKit
import Foundation
import ToolboxCore

enum ApplicationArtifactKind: String, Sendable {
  case support = "Application Support"
  case cache = "Cache"
  case preference = "Preference"
  case log = "Log"
  case container = "Container"
  case launchAgent = "LaunchAgent"
  case loginItem = "Login Item / Background Task"
  case packageReceipt = "Package receipt"
}

struct ApplicationArtifact: Identifiable, Sendable {
  let entry: StorageEntry
  let kind: ApplicationArtifactKind
  let confidence: CleanupConfidence
  let evidence: String

  var id: String { entry.id }
}

struct InstalledApplication: Identifiable, Sendable {
  let url: URL
  let name: String
  let bundleIdentifier: String?
  let bytes: Int64
  let leftovers: [ApplicationArtifact]
  var id: String { url.path }
  var totalBytes: Int64 { bytes + leftovers.reduce(0) { $0 + $1.entry.bytes } }
}

struct ApplicationScanner: Sendable {
  private let homeURL: URL

  init(homeURL: URL = FileManager.default.homeDirectoryForCurrentUser) {
    self.homeURL = homeURL.standardizedFileURL
  }

  func scan() -> [InstalledApplication] {
    let manager = FileManager()
    let home = homeURL
    let roots = [
      URL(fileURLWithPath: "/Applications"), home.appendingPathComponent("Applications"),
    ]
    let service = CleanerService(homeURL: home)
    let backgroundItems = backgroundItemsDump()
    var apps: [InstalledApplication] = []
    for root in roots {
      guard
        let contents = try? manager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
      else { continue }
      for url in contents where url.pathExtension.lowercased() == "app" {
        if Task.isCancelled { return apps }
        let name = url.deletingPathExtension().lastPathComponent
        let bundleID = Bundle(url: url)?.bundleIdentifier
        apps.append(
          .init(
            url: url,
            name: name,
            bundleIdentifier: bundleID,
            bytes: (try? service.size(of: url)) ?? 0,
            leftovers: findLeftovers(
              name: name, bundleID: bundleID, home: home, service: service,
              backgroundItems: backgroundItems)
          ))
      }
    }
    return apps.sorted { $0.totalBytes > $1.totalBytes }
  }

  func uninstall(_ app: InstalledApplication, includeLeftovers: Bool) -> TrashResult {
    let manager = FileManager()
    var moved = 0
    var bytes: Int64 = 0
    var errors: [String] = []
    var moves: [TrashMoveRecord] = []
    let appTarget = StorageEntry(url: app.url, bytes: app.bytes, modifiedAt: nil)
    let leftovers = includeLeftovers ? app.leftovers.filter { $0.confidence != .dangerous } : []
    let targets: [(StorageEntry, [URL])] =
      [(appTarget, applicationRoots())]
      + leftovers.map { ($0.entry, roots(for: $0.kind)) }
    for (target, allowedRoots) in targets {
      do {
        let validated = try PathSafetyPolicy.validate(
          candidate: target.url, allowedRoots: allowedRoots)
        var trashedURL: NSURL?
        try manager.trashItem(at: validated, resultingItemURL: &trashedURL)
        moved += 1
        bytes += target.bytes
        if let trashedURL {
          moves.append(
            TrashMoveRecord(
              originalPath: validated.path, trashPath: (trashedURL as URL).path,
              bytes: target.bytes))
        }
      } catch { errors.append("\(target.url.lastPathComponent): \(error.localizedDescription)") }
    }
    return TrashResult(
      movedCount: moved, movedBytes: bytes, errors: errors, reportURL: nil, moves: moves)
  }

  private func applicationRoots() -> [URL] {
    [URL(fileURLWithPath: "/Applications"), homeURL.appendingPathComponent("Applications")]
  }

  private func roots(for kind: ApplicationArtifactKind) -> [URL] {
    switch kind {
    case .support:
      [
        homeURL.appendingPathComponent("Library/Application Support"),
        homeURL.appendingPathComponent("Library/Saved Application State"),
      ]
    case .cache:
      [homeURL.appendingPathComponent("Library/Caches")]
    case .preference:
      [homeURL.appendingPathComponent("Library/Preferences")]
    case .log:
      [homeURL.appendingPathComponent("Library/Logs")]
    case .container:
      [homeURL.appendingPathComponent("Library/Containers")]
    case .launchAgent:
      [
        homeURL.appendingPathComponent("Library/LaunchAgents"),
        URL(fileURLWithPath: "/Library/LaunchAgents"),
        URL(fileURLWithPath: "/Library/LaunchDaemons"),
      ]
    case .loginItem, .packageReceipt:
      []
    }
  }

  private func findLeftovers(
    name: String, bundleID: String?, home: URL, service: CleanerService,
    backgroundItems: String
  )
    -> [ApplicationArtifact]
  {
    let roots: [(String, ApplicationArtifactKind)] = [
      ("Library/Application Support", .support), ("Library/Caches", .cache),
      ("Library/Preferences", .preference), ("Library/Logs", .log),
      ("Library/Saved Application State", .support), ("Library/Containers", .container),
    ]
    let normalizedName = Self.canonicalName(name)
    guard normalizedName.count >= 4 else { return [] }
    var output: [ApplicationArtifact] = []
    for (relativeRoot, kind) in roots {
      let root = home.appendingPathComponent(relativeRoot)
      guard
        let contents = try? FileManager.default.contentsOfDirectory(
          at: root, includingPropertiesForKeys: [.contentModificationDateKey])
      else { continue }
      for url in contents {
        let candidate = url.lastPathComponent.lowercased()
        let bundleMatch =
          bundleID.map {
            candidate == $0.lowercased() || candidate.hasPrefix($0.lowercased() + ".")
          } ?? false
        let nameMatch = Self.matchesLeftoverName(candidate, applicationName: name)
        guard bundleMatch || nameMatch else {
          continue
        }
        let confidence: CleanupConfidence = bundleMatch ? .safe : .review
        output.append(
          ApplicationArtifact(
            entry: StorageEntry(
              url: url, bytes: (try? service.size(of: url)) ?? 0, modifiedAt: nil),
            kind: kind, confidence: confidence,
            evidence: bundleMatch ? "Bundle ID khớp chính xác" : "Tên thành phần khớp; cần xem lại")
        )
      }
    }
    output += findLaunchAgents(name: name, bundleID: bundleID, home: home, service: service)
    output += findPackageReceipts(name: name, bundleID: bundleID)
    output += findBackgroundItemEvidence(
      name: name, bundleID: bundleID, home: home, dump: backgroundItems, service: service)
    return Dictionary(grouping: output, by: \.id).compactMap { $0.value.first }.sorted {
      $0.entry.bytes > $1.entry.bytes
    }
  }

  private func findLaunchAgents(
    name: String, bundleID: String?, home: URL, service: CleanerService
  ) -> [ApplicationArtifact] {
    let roots = [
      home.appendingPathComponent("Library/LaunchAgents"),
      URL(fileURLWithPath: "/Library/LaunchAgents"),
      URL(fileURLWithPath: "/Library/LaunchDaemons"),
    ]
    return roots.flatMap { root -> [ApplicationArtifact] in
      let files =
        (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil))
        ?? []
      return files.compactMap { url in
        guard url.pathExtension == "plist", let data = try? Data(contentsOf: url),
          let text = String(data: data, encoding: .utf8)
        else { return nil }
        let bundleMatch = bundleID.map { text.localizedCaseInsensitiveContains($0) } ?? false
        let nameMatch =
          text.localizedCaseInsensitiveContains(name)
          || Self.matchesLeftoverName(url.lastPathComponent, applicationName: name)
        guard bundleMatch || nameMatch else { return nil }
        return ApplicationArtifact(
          entry: StorageEntry(url: url, bytes: (try? service.size(of: url)) ?? 0, modifiedAt: nil),
          kind: .launchAgent, confidence: .review,
          evidence: bundleMatch
            ? "Launch item tham chiếu Bundle ID" : "Launch item tham chiếu tên ứng dụng")
      }
    }
  }

  private func findPackageReceipts(name: String, bundleID: String?) -> [ApplicationArtifact] {
    let root = URL(fileURLWithPath: "/var/db/receipts")
    let files =
      (try? FileManager.default.contentsOfDirectory(
        at: root, includingPropertiesForKeys: [.fileSizeKey])) ?? []
    return files.compactMap { url in
      let candidate = url.deletingPathExtension().lastPathComponent
      let bundleMatch =
        bundleID.map {
          candidate.caseInsensitiveCompare($0) == .orderedSame
            || candidate.lowercased().hasPrefix($0.lowercased() + ".")
        } ?? false
      guard bundleMatch || Self.matchesLeftoverName(candidate, applicationName: name) else {
        return nil
      }
      let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
      return ApplicationArtifact(
        entry: StorageEntry(url: url, bytes: size, modifiedAt: nil),
        kind: .packageReceipt, confidence: .dangerous,
        evidence: "Receipt hệ thống chỉ dùng làm bằng chứng; Toolbox không tự xóa")
    }
  }

  private func backgroundItemsDump() -> String {
    let executable = URL(fileURLWithPath: "/usr/bin/sfltool")
    guard FileManager.default.isExecutableFile(atPath: executable.path) else { return "" }
    let process = Process()
    let pipe = Pipe()
    process.executableURL = executable
    process.arguments = ["dumpbtm"]
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    do {
      try process.run()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      process.waitUntilExit()
      guard process.terminationStatus == 0, data.count < 8_000_000 else { return "" }
      return String(decoding: data, as: UTF8.self)
    } catch { return "" }
  }

  private func findBackgroundItemEvidence(
    name: String, bundleID: String?, home: URL, dump: String, service: CleanerService
  ) -> [ApplicationArtifact] {
    guard !dump.isEmpty else { return [] }
    let bundleMatch = bundleID.map { dump.localizedCaseInsensitiveContains($0) } ?? false
    let nameMatch = dump.localizedCaseInsensitiveContains(name)
    guard bundleMatch || nameMatch else { return [] }
    let database = home.appendingPathComponent(
      "Library/Application Support/com.apple.backgroundtaskmanagementagent/backgrounditems.btm")
    return [
      ApplicationArtifact(
        entry: StorageEntry(
          url: database, bytes: (try? service.size(of: database)) ?? 0, modifiedAt: nil),
        kind: .loginItem, confidence: .dangerous,
        evidence:
          "sfltool phát hiện login/background item; chỉ hiển thị bằng chứng, Toolbox không xóa database hệ thống"
      )
    ]
  }

  static func matchesLeftoverName(_ candidate: String, applicationName: String) -> Bool {
    let application = canonicalName(applicationName)
    guard application.count >= 4 else { return false }
    let components = candidate.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
    guard !components.isEmpty else { return false }
    if canonicalName(candidate) == application || components.contains(application) { return true }
    return components.indices.contains { index in
      canonicalName(components[index...].joined()) == application
    }
  }

  private static func canonicalName<S: StringProtocol>(_ value: S) -> String {
    value.lowercased().filter { $0.isLetter || $0.isNumber }
  }
}

@MainActor
final class ApplicationViewModel: ObservableObject {
  @Published var applications: [InstalledApplication] = []
  @Published var isWorking = false
  @Published var status = "Quét ứng dụng để tìm dữ liệu còn sót"
  @Published var errorMessage: String?
  private let scanner = ApplicationScanner()
  private let history = HistoryStore()
  private let activityLedger = ActivityLedger()

  func scan() {
    isWorking = true
    ScanActivityRegistry.shared.begin()
    status = "Đang phân tích ứng dụng và dữ liệu liên quan…"
    let scanner = self.scanner
    Task {
      applications = await Task.detached { scanner.scan() }.value
      ScanActivityRegistry.shared.end()
      isWorking = false
      status = "Tìm thấy \(applications.count) ứng dụng"
    }
  }

  func uninstall(_ app: InstalledApplication, includeLeftovers: Bool) {
    isWorking = true
    let attemptedPaths =
      [app.url.path]
      + (includeLeftovers
        ? app.leftovers.filter { $0.confidence != .dangerous }.map { $0.entry.url.path } : [])
    let scanner = self.scanner
    let history = self.history
    let activityLedger = self.activityLedger
    Task {
      let result = await Task.detached {
        scanner.uninstall(app, includeLeftovers: includeLeftovers)
      }.value
      history.record(
        action: "Gỡ ứng dụng: \(app.name)",
        paths: attemptedPaths,
        bytes: result.movedBytes,
        recoverable: true, note: "Đã chuyển vào Trash", moves: result.moves)
      try? activityLedger.append(
        ActivityEntry(
          kind: .cleanup, status: result.errors.isEmpty ? .succeeded : .failed,
          paths: attemptedPaths, affectedBytes: result.movedBytes,
          recoverable: !result.moves.isEmpty, errors: result.errors))
      errorMessage = result.errors.isEmpty ? nil : result.errors.joined(separator: "\n")
      isWorking = false
      scan()
    }
  }

  func reveal(_ url: URL) { NSWorkspace.shared.activateFileViewerSelecting([url]) }
}
