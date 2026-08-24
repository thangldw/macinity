import Foundation

public enum SafetyLevel: String, Codable, CaseIterable, Comparable, Sendable {
  case safe
  case review
  case protected

  public static func < (lhs: SafetyLevel, rhs: SafetyLevel) -> Bool {
    lhs.rank < rhs.rank
  }

  private var rank: Int {
    switch self {
    case .safe: 0
    case .review: 1
    case .protected: 2
    }
  }
}

public enum PathSafetyError: Error, Equatable, Sendable {
  case emptyRoots
  case broadTarget
  case outsideAllowedRoots
}

public enum PathSafetyPolicy {
  public static func validate(candidate: URL, allowedRoots: [URL]) throws -> URL {
    guard !allowedRoots.isEmpty else { throw PathSafetyError.emptyRoots }

    let resolved = resolveExistingPrefix(of: candidate)
    let home = FileManager.default.homeDirectoryForCurrentUser
      .resolvingSymlinksInPath().standardizedFileURL
    guard resolved.path != "/", resolved.path != home.path else {
      throw PathSafetyError.broadTarget
    }

    let isInsideAllowedRoot = allowedRoots.contains { root in
      let resolvedRoot = root.resolvingSymlinksInPath().standardizedFileURL
      guard resolvedRoot.path != "/" else { return false }
      return resolved.path.hasPrefix(resolvedRoot.path + "/")
    }
    guard isInsideAllowedRoot else { throw PathSafetyError.outsideAllowedRoots }
    return resolved
  }

  private static func resolveExistingPrefix(of candidate: URL) -> URL {
    var existingPrefix = candidate.standardizedFileURL
    var missingComponents: [String] = []

    while existingPrefix.path != "/",
      !FileManager.default.fileExists(atPath: existingPrefix.path)
    {
      missingComponents.append(existingPrefix.lastPathComponent)
      existingPrefix.deleteLastPathComponent()
    }

    var resolved = existingPrefix.resolvingSymlinksInPath().standardizedFileURL
    for component in missingComponents.reversed() {
      resolved.appendPathComponent(component)
    }
    return resolved.standardizedFileURL
  }
}
