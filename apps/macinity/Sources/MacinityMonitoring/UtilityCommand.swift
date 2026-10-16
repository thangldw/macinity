import Foundation

/// Closed command catalog. No shell, privilege escalation, or user-supplied executable arguments.
public enum UtilityCommand: Sendable {
  case launchChange(path: String, label: String, load: Bool)
  case backgroundItems
  case launchList
  case launchStatus(String)
  case profileDevices
  case externalDisks
  case diskInfo(String)
  case fileLocks(String)
  case processCommand(Int32)

  var specification: (path: String, arguments: [String], timeout: Double) {
    get throws {
      switch self {
      case .launchChange(let path, let label, let load):
        let url = URL(fileURLWithPath: path)
        let root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
          "Library/LaunchAgents")
        guard Self.validLabel(label), url.deletingLastPathComponent() == root,
          url.pathExtension == "plist", url.resolvingSymlinksInPath().path == path
        else { throw CocoaError(.validationMissingMandatoryProperty) }
        return (
          "/bin/launchctl",
          load ? ["bootstrap", "gui/\(getuid())", path] : ["bootout", "gui/\(getuid())/\(label)"],
          10
        )
      case .backgroundItems: return ("/usr/bin/sfltool", ["dumpbtm"], 10)
      case .launchList: return ("/bin/launchctl", ["list"], 5)
      case .launchStatus(let label):
        guard Self.validLabel(label) else { throw CocoaError(.validationMissingMandatoryProperty) }
        return ("/bin/launchctl", ["print", "gui/\(getuid())/\(label)"], 5)
      case .profileDevices:
        return (
          "/usr/sbin/system_profiler",
          [
            "SPUSBDataType", "SPThunderboltDataType", "SPDisplaysDataType", "SPAudioDataType",
            "SPBluetoothDataType", "-json", "-detailLevel", "mini",
          ], 30
        )
      case .externalDisks: return ("/usr/sbin/diskutil", ["list", "-plist", "external"], 8)
      case .diskInfo(let identifier):
        guard Self.validDisk(identifier) else {
          throw CocoaError(.validationMissingMandatoryProperty)
        }
        return ("/usr/sbin/diskutil", ["info", "-plist", identifier], 5)
      case .fileLocks(let mount):
        guard mount.hasPrefix("/Volumes/"), !mount.contains("\0") else {
          throw CocoaError(.validationMissingMandatoryProperty)
        }
        return ("/usr/sbin/lsof", ["-n", "-P", "-Fpcfn", "+f", "--", mount], 10)
      case .processCommand(let pid):
        guard pid > 0 else { throw CocoaError(.validationMissingMandatoryProperty) }
        return ("/bin/ps", ["-ww", "-p", String(pid), "-o", "command="], 3)
      }
    }
  }
  public static func validLabel(_ label: String) -> Bool {
    !label.isEmpty && label.count <= 255
      && label.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || "._-".contains($0)) }
  }
  public static func validDisk(_ id: String) -> Bool {
    id.range(of: #"^disk[0-9]+(s[0-9]+)*$"#, options: .regularExpression) != nil
  }
  public func read() throws -> UtilityCommandResult {
    let result = try NetworkToolsProcess.read(.utility(self))
    return UtilityCommandResult(text: result.text, status: result.status)
  }
}

public struct UtilityCommandResult: Sendable {
  public let text: String
  public let status: Int32
}
