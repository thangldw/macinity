import Foundation

public enum PackageAction: String, Sendable { case version, inventory, upgrade, uninstall }
public struct PackageCommand: Sendable {
  public let executable: String
  public let tool: String
  public let action: PackageAction
  public let package: String
  public let cask: Bool
  public init(
    executable: String, tool: String, action: PackageAction, package: String = "",
    cask: Bool = false
  ) {
    self.executable = executable
    self.tool = tool
    self.action = action
    self.package = package
    self.cask = cask
  }
  public var isMutation: Bool { action == .upgrade || action == .uninstall }
  public static func validPackage(_ name: String) -> Bool {
    name.count <= 200 && !name.contains("..")
      && name.range(
        of:
          #"^(?:@[A-Za-z0-9][A-Za-z0-9._-]*/)?[A-Za-z0-9][A-Za-z0-9._+-]*(?:/[A-Za-z0-9][A-Za-z0-9._+-]*){0,2}$"#,
        options: .regularExpression) != nil
  }
  var specification: (path: String, arguments: [String], timeout: Double) {
    get throws {
      let url = URL(fileURLWithPath: executable)
      guard executable.hasPrefix("/"), url.lastPathComponent == tool,
        !executable.contains("\0"), FileManager.default.isExecutableFile(atPath: executable),
        [
          "brew", "python3", "node", "npm", "go", "rustc", "cargo", "git", "mise", "uv", "bun",
          "deno", "docker", "podman", "nix", "java", "duckdb", "terraform", "kubectl", "orb",
        ].contains(tool)
      else { throw CocoaError(.validationMissingMandatoryProperty) }
      if action == .version {
        let args =
          tool == "go"
          ? ["version"]
          : tool == "java"
            ? ["-version"]
            : tool == "kubectl" ? ["version", "--client=true", "--output=json"] : ["--version"]
        return (executable, args, 10)
      }
      guard ["brew", "python3", "npm"].contains(tool) else { throw CocoaError(.featureUnsupported) }
      if action == .inventory {
        switch tool {
        case "brew": return (executable, ["info", "--json=v2", "--installed"], 30)
        case "python3":
          return (
            executable,
            [
              "-I", "-c",
              "import json,sys,importlib.metadata as m; print(json.dumps({'executable':sys.executable,'prefix':sys.prefix,'base_prefix':sys.base_prefix,'packages':[{'name':d.metadata.get('Name',''),'version':d.version} for d in m.distributions()]}))",
            ], 15
          )
        default:
          return (executable, ["list", "--global", "--depth=0", "--json", "--ignore-scripts"], 30)
        }
      }
      guard Self.validPackage(package),
        tool != "python3" || (!package.contains("/") && !package.contains("@"))
      else {
        throw CocoaError(.validationMissingMandatoryProperty)
      }
      switch tool {
      case "brew":
        return (
          executable,
          [action == .upgrade ? "upgrade" : "uninstall", cask ? "--cask" : "--formula", package],
          600
        )
      case "python3":
        return (
          executable,
          action == .upgrade
            ? [
              "-I", "-m", "pip", "--disable-pip-version-check", "--no-input", "install",
              "--upgrade", package,
            ]
            : [
              "-I", "-m", "pip", "--disable-pip-version-check", "--no-input", "uninstall", "-y",
              package,
            ], 600
        )
      default:
        return (
          executable,
          [
            action == .upgrade ? "update" : "uninstall", "--global", "--ignore-scripts",
            "--no-audit", "--no-fund", package,
          ], 600
        )
      }
    }
  }
  public var preview: String {
    ([executable] + ((try? specification.arguments) ?? [])).map {
      "'" + $0.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }.joined(separator: " ")
  }
  public func run() throws -> UtilityCommandResult {
    if isMutation {
      let fresh = try PackageCommand(executable: executable, tool: tool, action: .inventory).run()
      guard fresh.status == 0 else { throw CocoaError(.fileReadUnknown) }
      let inventory = try PackageInventory.parse(fresh.text, tool: tool)
      guard inventory.entries.contains(where: { $0.name == package && $0.cask == cask }),
        tool != "python3" || inventory.isVirtualEnvironment
      else { throw CocoaError(.validationMissingMandatoryProperty) }
    }
    let result = try NetworkToolsProcess.read(.package(self))
    return .init(text: result.text, status: result.status)
  }
}
public struct PackageEntry: Sendable, Identifiable {
  public var id: String { name + (cask ? ":cask" : ":package") }
  public let name: String
  public let version: String
  public let cask: Bool
}
public struct PackageInventory: Sendable {
  public let entries: [PackageEntry]
  public let environment: String
  public let isVirtualEnvironment: Bool
  public static func parse(_ text: String, tool: String) throws -> Self {
    guard let root = try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any]
    else { throw CocoaError(.fileReadCorruptFile) }
    var entries: [PackageEntry] = []
    var environment = ""
    var virtual = false
    switch tool {
    case "brew":
      for item in root["formulae"] as? [[String: Any]] ?? [] {
        if let name = item["full_name"] as? String ?? item["name"] as? String {
          let versions = (item["installed"] as? [[String: Any]] ?? []).compactMap {
            $0["version"] as? String
          }
          entries.append(.init(name: name, version: versions.joined(separator: ", "), cask: false))
        }
      }
      for item in root["casks"] as? [[String: Any]] ?? [] {
        if let name = item["token"] as? String {
          let version =
            item["installed"] as? String ?? (item["installed"] as? [String])?.joined(
              separator: ", ") ?? "Unknown"
          entries.append(.init(name: name, version: version, cask: true))
        }
      }
    case "python3":
      environment = root["prefix"] as? String ?? ""
      let base = root["base_prefix"] as? String ?? ""
      virtual = !environment.isEmpty && !base.isEmpty && base != environment
      for item in root["packages"] as? [[String: Any]] ?? [] {
        if let name = item["name"] as? String, let version = item["version"] as? String {
          entries.append(.init(name: name, version: version, cask: false))
        }
      }
    case "npm":
      environment = root["path"] as? String ?? ""
      for (name, item) in root["dependencies"] as? [String: [String: Any]] ?? [:] {
        entries.append(
          .init(name: name, version: item["version"] as? String ?? "Unknown", cask: false))
      }
    default: throw CocoaError(.featureUnsupported)
    }
    guard entries.count <= 10000 else { throw CocoaError(.fileReadTooLarge) }
    return .init(
      entries: entries.sorted { $0.name < $1.name }, environment: environment,
      isVirtualEnvironment: virtual)
  }
}
