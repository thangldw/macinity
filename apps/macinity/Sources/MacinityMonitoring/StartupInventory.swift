import CryptoKit
import Foundation

public struct StartupEntry: Identifiable, Sendable {
  public var id: String { path }
  public let label: String
  public let path: String
  public let owner: String
  public let program: String
  public let registered: Bool?
  public let pid: Int32?
  public let lastExit: String?
  public let fingerprint: String
  public let canChange: Bool
}

public struct StartupInventory: Sendable {
  public let entries: [StartupEntry]
  public let omitted: Int
  public let observedAt: Date

  public static func read() throws -> Self {
    let result = try UtilityCommand.launchList.read()
    let services = parseServices(result.status == 0 ? result.text : "")
    let fm = FileManager.default
    let userRoot = fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
      .path
    var entries: [StartupEntry] = []
    var omitted = 0
    for root in [
      userRoot, "/Library/LaunchAgents", "/Library/LaunchDaemons", "/System/Library/LaunchAgents",
      "/System/Library/LaunchDaemons",
    ] {
      guard
        let urls = try? fm.contentsOfDirectory(
          at: URL(fileURLWithPath: root), includingPropertiesForKeys: nil)
      else { continue }
      for url in urls.sorted(by: { $0.path < $1.path }) where url.pathExtension == "plist" {
        try Task.checkCancellation()
        guard entries.count < 1000, let attrs = try? fm.attributesOfItem(atPath: url.path),
          (attrs[.size] as? NSNumber)?.intValue ?? Int.max <= 1_048_576,
          attrs[.type] as? FileAttributeType == .typeRegular,
          let data = try? Data(contentsOf: url),
          let plist = try? PropertyListSerialization.propertyList(from: data, format: nil)
            as? [String: Any],
          let label = plist["Label"] as? String, UtilityCommand.validLabel(label)
        else {
          omitted += 1
          continue
        }
        let program =
          plist["Program"] as? String ?? (plist["ProgramArguments"] as? [String])?.first ?? ""
        let service = services[label]
        let userDomain = !root.hasSuffix("LaunchDaemons")
        let owned = (attrs[.ownerAccountID] as? NSNumber)?.uint32Value == getuid()
        entries.append(
          .init(
            label: label, path: url.path,
            owner: attrs[.ownerAccountName] as? String ?? "Unknown",
            program: String(program.prefix(2048)),
            registered: userDomain && result.status == 0 ? service != nil : nil,
            pid: service?.pid, lastExit: service?.exit,
            fingerprint: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined(),
            canChange: root == userRoot && owned && result.status == 0 && !program.isEmpty
              && url.resolvingSymlinksInPath().path == url.path))
      }
    }
    return Self(entries: entries, omitted: omitted, observedAt: Date())
  }
  public static func parseServices(_ text: String) -> [String: (pid: Int32?, exit: String)] {
    var result: [String: (Int32?, String)] = [:]
    for line in text.split(separator: "\n").dropFirst() {
      let fields = line.split(whereSeparator: \.isWhitespace)
      guard fields.count == 3, UtilityCommand.validLabel(String(fields[2])) else { continue }
      result[String(fields[2])] = (Int32(fields[0]), String(fields[1]))
    }
    return result
  }
  /// A reversible runtime registration change; never rewrites or deletes a launch plist.
  public static func change(_ expected: StartupEntry, load: Bool) throws -> UtilityCommandResult {
    guard expected.canChange,
      let current = try read().entries.first(where: { $0.path == expected.path }),
      current.canChange, current.fingerprint == expected.fingerprint,
      current.registered == expected.registered, current.registered != load
    else { throw CocoaError(.fileReadUnknown) }
    let command = UtilityCommand.launchChange(path: current.path, label: current.label, load: load)
    let result = try command.read()
    guard result.status == 0 else { return result }
    let verification = try read().entries.first { $0.path == expected.path }
    guard verification?.registered == load else { throw CocoaError(.fileReadUnknown) }
    return result
  }
}
