import CoreServices
import Foundation

struct SnapshotDiffEngine: Sendable {
  func compare(
    before: SystemSnapshot, after: SystemSnapshot, events: [FileSystemEvent] = [],
    categoryForPath: @Sendable (String) -> SnapshotCategory? = { _ in nil }
  ) -> SnapshotComparison {
    let oldItems = Dictionary(uniqueKeysWithValues: before.items.map { ($0.id, $0) })
    let newItems = Dictionary(uniqueKeysWithValues: after.items.map { ($0.id, $0) })
    let identifiers = Set(oldItems.keys).union(newItems.keys)
    let applications = Array(oldItems.values) + Array(newItems.values)
    let applicationCandidates = Dictionary(
      grouping: applications.filter { $0.category == .application }, by: \.id
    )
    .compactMap { $0.value.first }

    var changes = identifiers.compactMap { identifier -> ChangeRecord? in
      let oldItem = oldItems[identifier]
      let newItem = newItems[identifier]
      let kind: ChangeKind

      switch (oldItem, newItem) {
      case (nil, .some): kind = .added
      case (.some, nil): kind = .removed
      case (.some(let old), .some(let new)):
        guard old.comparisonFingerprint != new.comparisonFingerprint else { return nil }
        kind = .modified
      case (nil, nil): return nil
      }

      let item = newItem ?? oldItem!
      let assessment = riskAssessment(for: item, kind: kind)
      return ChangeRecord(
        id: "\(kind.rawValue)|\(identifier)",
        kind: kind,
        risk: assessment.risk,
        before: oldItem,
        after: newItem,
        riskReason: assessment.reason,
        attributedApplication: attribution(for: item, applications: applicationCandidates)
      )
    }
    let changedPaths = Set(changes.map { $0.item.path })
    let eventChanges = Dictionary(grouping: events, by: { $0.path }).compactMap {
      path, pathEvents -> ChangeRecord? in
      let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
      guard !changedPaths.contains(standardizedPath),
        let category = categoryForPath(standardizedPath),
        let latest = pathEvents.max(by: { $0.occurredAt < $1.occurredAt })
      else { return nil }
      let removed = latest.flags & UInt32(kFSEventStreamEventFlagItemRemoved) != 0
      let created = latest.flags & UInt32(kFSEventStreamEventFlagItemCreated) != 0
      let exists = FileManager.default.fileExists(atPath: standardizedPath)
      let kind: ChangeKind = removed && !exists ? .removed : created ? .added : .modified
      let values = try? URL(fileURLWithPath: standardizedPath).resourceValues(
        forKeys: [.fileSizeKey, .contentModificationDateKey])
      let item = SnapshotItem(
        id: "\(category.rawValue)|\(standardizedPath)", category: category,
        name: URL(fileURLWithPath: standardizedPath).lastPathComponent,
        path: standardizedPath, size: Int64(values?.fileSize ?? 0),
        modifiedAt: values?.contentModificationDate, bundleIdentifier: nil, version: nil,
        teamIdentifier: nil, signatureStatus: nil,
        ownerHint: "FSEvents • \(pathEvents.count) event")
      let assessment = riskAssessment(for: item, kind: kind)
      return ChangeRecord(
        id: "event|\(kind.rawValue)|\(item.id)", kind: kind, risk: assessment.risk,
        before: kind == .removed ? item : nil, after: kind == .removed ? nil : item,
        riskReason: "\(assessment.reason) Phát hiện thời gian thực bằng FSEvents.",
        attributedApplication: attribution(for: item, applications: applicationCandidates))
    }
    changes.append(contentsOf: eventChanges)
    changes.sort {
      if $0.risk != $1.risk { return $0.risk > $1.risk }
      if $0.kind != $1.kind { return $0.kind.rawValue < $1.kind.rawValue }
      return $0.item.name.localizedStandardCompare($1.item.name) == .orderedAscending
    }

    return SnapshotComparison(before: before, after: after, changes: changes)
  }

  private func riskAssessment(for item: SnapshotItem, kind: ChangeKind) -> (
    risk: ChangeRisk, reason: String
  ) {
    let team = item.teamIdentifier.map { " Team ID: \($0)." } ?? ""
    let signature = item.signatureStatus.map { " Chữ ký: \($0)." } ?? ""
    switch item.category {
    case .privilegedHelper, .systemExtension:
      return (
        kind == .removed ? .review : .important,
        "Thành phần đặc quyền hoặc system extension có thể chạy ngoài tiến trình ứng dụng.\(team)\(signature)"
      )
    case .kernelExtension:
      return (
        kind == .removed ? .review : .important,
        "Kernel extension tác động ở mức hệ thống và cần được xem xét cẩn thận.\(team)\(signature)"
      )
    case .launchDaemon:
      return (
        kind == .removed ? .review : .important,
        "LaunchDaemon mới có thể chạy nền với quyền hệ thống/root.\(team)\(signature)"
      )
    case .launchAgent, .loginItem, .backgroundTask:
      return (
        .review,
        "Thành phần persistence có thể tự chạy khi đăng nhập hoặc trong nền.\(team)\(signature)"
      )
    case .configurationProfile:
      return (
        kind == .removed ? .review : .important,
        "Configuration profile có thể thay đổi policy và thiết lập quản trị của macOS."
      )
    case .shellConfiguration:
      return (
        .review,
        "Shell/PATH thay đổi có thể tác động mọi terminal session và command được thực thi."
      )
    case .browserExtension:
      return (.review, "Browser extension có thể đọc hoặc thay đổi dữ liệu trong trình duyệt.")
    case .application:
      return (
        kind == .modified ? .review : .informational,
        "Application bundle thay đổi; kiểm tra version, Team ID và chữ ký.\(team)\(signature)"
      )
    case .packageReceipt:
      return (.informational, "Package receipt là bằng chứng cài đặt do Installer ghi lại.")
    case .applicationSupport, .cache, .preference, .container:
      return (.informational, "Dữ liệu người dùng hoặc metadata ứng dụng thay đổi trong Library.")
    }
  }

  private func attribution(for item: SnapshotItem, applications: [SnapshotItem]) -> String? {
    if item.category == .application { return item.name }
    let path = item.path.lowercased()
    let owner = item.ownerHint?.lowercased()
    let ranked = applications.compactMap { application -> (SnapshotItem, Int)? in
      var score = 0
      if let bundleID = application.bundleIdentifier?.lowercased() {
        if path.contains(bundleID) { score += 6 }
        if owner == bundleID || owner?.hasPrefix(bundleID + ".") == true { score += 6 }
      }
      if let team = application.teamIdentifier, team == item.teamIdentifier { score += 3 }
      let normalizedName = application.name.lowercased().replacingOccurrences(of: " ", with: "")
      if normalizedName.count >= 4,
        path.replacingOccurrences(of: " ", with: "").contains(normalizedName)
      {
        score += 2
      }
      if let itemDate = item.modifiedAt, let applicationDate = application.modifiedAt,
        abs(itemDate.timeIntervalSince(applicationDate)) <= 15 * 60
      {
        score += 1
      }
      return score > 0 ? (application, score) : nil
    }
    return ranked.max { $0.1 < $1.1 }?.0.name
  }
}

extension SnapshotComparison {
  func compacted() -> SnapshotComparison {
    let identifiers = Set(
      changes.flatMap { change in
        [change.before?.id, change.after?.id].compactMap { $0 }
      })

    return SnapshotComparison(
      id: id,
      before: compact(snapshot: before, identifiers: identifiers),
      after: compact(snapshot: after, identifiers: identifiers),
      changes: changes
    )
  }

  private func compact(snapshot: SystemSnapshot, identifiers: Set<String>) -> SystemSnapshot {
    SystemSnapshot(
      id: snapshot.id,
      name: snapshot.name,
      createdAt: snapshot.createdAt,
      items: snapshot.items.filter { identifiers.contains($0.id) },
      inaccessiblePaths: snapshot.inaccessiblePaths,
      truncated: snapshot.truncated
    )
  }
}
