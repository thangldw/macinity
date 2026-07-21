import Foundation

struct SnapshotDiffEngine: Sendable {
  func compare(before: SystemSnapshot, after: SystemSnapshot) -> SnapshotComparison {
    let oldItems = Dictionary(uniqueKeysWithValues: before.items.map { ($0.id, $0) })
    let newItems = Dictionary(uniqueKeysWithValues: after.items.map { ($0.id, $0) })
    let identifiers = Set(oldItems.keys).union(newItems.keys)

    let changes = identifiers.compactMap { identifier -> ChangeRecord? in
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
      return ChangeRecord(
        id: "\(kind.rawValue)|\(identifier)",
        kind: kind,
        risk: risk(for: item.category, kind: kind),
        before: oldItem,
        after: newItem
      )
    }
    .sorted {
      if $0.risk != $1.risk { return $0.risk > $1.risk }
      if $0.kind != $1.kind { return $0.kind.rawValue < $1.kind.rawValue }
      return $0.item.name.localizedStandardCompare($1.item.name) == .orderedAscending
    }

    return SnapshotComparison(before: before, after: after, changes: changes)
  }

  private func risk(for category: SnapshotCategory, kind: ChangeKind) -> ChangeRisk {
    switch category {
    case .privilegedHelper, .systemExtension:
      return kind == .removed ? .review : .important
    case .launchDaemon:
      return kind == .removed ? .review : .important
    case .launchAgent:
      return .review
    case .application:
      return kind == .modified ? .review : .informational
    case .applicationSupport, .cache, .preference, .container:
      return .informational
    }
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
