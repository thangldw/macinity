import Foundation
import Security

struct ScanLocation: Hashable, Sendable {
  let category: SnapshotCategory
  let url: URL
  let maximumDepth: Int
}

struct SnapshotConfiguration: Sendable {
  let locations: [ScanLocation]
  let maximumItems: Int

  static func standard(fileManager: FileManager = .default) -> SnapshotConfiguration {
    let home = fileManager.homeDirectoryForCurrentUser
    let userLibrary = home.appendingPathComponent("Library", isDirectory: true)
    return SnapshotConfiguration(
      locations: [
        ScanLocation(
          category: .application, url: URL(fileURLWithPath: "/Applications"), maximumDepth: 1),
        ScanLocation(
          category: .application, url: home.appendingPathComponent("Applications"), maximumDepth: 1),
        ScanLocation(
          category: .launchAgent, url: userLibrary.appendingPathComponent("LaunchAgents"),
          maximumDepth: 1),
        ScanLocation(
          category: .launchAgent, url: URL(fileURLWithPath: "/Library/LaunchAgents"),
          maximumDepth: 1),
        ScanLocation(
          category: .launchDaemon, url: URL(fileURLWithPath: "/Library/LaunchDaemons"),
          maximumDepth: 1),
        ScanLocation(
          category: .privilegedHelper, url: URL(fileURLWithPath: "/Library/PrivilegedHelperTools"),
          maximumDepth: 1),
        ScanLocation(
          category: .systemExtension, url: URL(fileURLWithPath: "/Library/SystemExtensions"),
          maximumDepth: 3),
        ScanLocation(
          category: .applicationSupport,
          url: userLibrary.appendingPathComponent("Application Support"), maximumDepth: 1),
        ScanLocation(
          category: .applicationSupport, url: URL(fileURLWithPath: "/Library/Application Support"),
          maximumDepth: 1),
        ScanLocation(
          category: .cache, url: userLibrary.appendingPathComponent("Caches"), maximumDepth: 1),
        ScanLocation(
          category: .preference, url: userLibrary.appendingPathComponent("Preferences"),
          maximumDepth: 1),
        ScanLocation(
          category: .container, url: userLibrary.appendingPathComponent("Containers"),
          maximumDepth: 1),
        ScanLocation(
          category: .container, url: userLibrary.appendingPathComponent("Group Containers"),
          maximumDepth: 1),
      ],
      maximumItems: 50_000
    )
  }
}

struct SystemSnapshotScanner: Sendable {
  let configuration: SnapshotConfiguration

  init(configuration: SnapshotConfiguration = .standard()) {
    self.configuration = configuration
  }

  func capture(name: String) -> SystemSnapshot {
    var items: [SnapshotItem] = []
    var inaccessiblePaths: [String] = []
    var truncated = false

    for location in configuration.locations {
      guard items.count < configuration.maximumItems else {
        truncated = true
        break
      }
      let outcome = scan(
        location: location, remainingLimit: configuration.maximumItems - items.count)
      items.append(contentsOf: outcome.items)
      inaccessiblePaths.append(contentsOf: outcome.inaccessiblePaths)
      truncated = truncated || outcome.truncated
    }

    return SystemSnapshot(
      name: name,
      items: items.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending },
      inaccessiblePaths: Array(Set(inaccessiblePaths)).sorted(),
      truncated: truncated
    )
  }

  private func scan(location: ScanLocation, remainingLimit: Int) -> ScanOutcome {
    let manager = FileManager.default
    var isDirectory: ObjCBool = false
    guard manager.fileExists(atPath: location.url.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      return ScanOutcome()
    }

    let keys: [URLResourceKey] = [
      .isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey, .contentModificationDateKey,
      .fileSizeKey, .totalFileAllocatedSizeKey,
    ]
    guard
      let enumerator = manager.enumerator(
        at: location.url,
        includingPropertiesForKeys: keys,
        options: [.skipsHiddenFiles, .skipsPackageDescendants],
        errorHandler: { _, _ in true })
    else {
      return ScanOutcome(inaccessiblePaths: [location.url.path])
    }

    let rootDepth = location.url.standardizedFileURL.pathComponents.count
    var result: [SnapshotItem] = []
    var inaccessible: [String] = []
    var truncated = false

    for case let url as URL in enumerator {
      if result.count >= remainingLimit {
        truncated = true
        break
      }

      let depth = url.standardizedFileURL.pathComponents.count - rootDepth
      if depth >= location.maximumDepth { enumerator.skipDescendants() }
      guard depth <= location.maximumDepth else { continue }

      do {
        let values = try url.resourceValues(forKeys: Set(keys))
        if values.isSymbolicLink == true {
          enumerator.skipDescendants()
          continue
        }
        if location.category == .application, url.pathExtension.lowercased() != "app" { continue }
        if location.category == .preference, values.isDirectory == true { continue }
        if let item = makeItem(url: url, category: location.category, values: values) {
          result.append(item)
        }
      } catch {
        inaccessible.append(url.path)
      }
    }

    return ScanOutcome(items: result, inaccessiblePaths: inaccessible, truncated: truncated)
  }

  private func makeItem(
    url: URL, category: SnapshotCategory, values: URLResourceValues
  ) -> SnapshotItem? {
    var name = url.lastPathComponent
    var bundleIdentifier: String?
    var version: String?
    var ownerHint: String?
    var teamIdentifier: String?
    var signatureStatus: String?

    if category == .application {
      let bundle = Bundle(url: url)
      name =
        bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? url.deletingPathExtension().lastPathComponent
      bundleIdentifier = bundle?.bundleIdentifier
      version = bundle?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
      let signature = signatureDetails(for: url)
      teamIdentifier = signature.teamIdentifier
      signatureStatus = signature.status
      ownerHint = bundleIdentifier
    } else if [.launchAgent, .launchDaemon].contains(category) {
      let metadata = propertyListMetadata(at: url)
      name = metadata.label ?? url.deletingPathExtension().lastPathComponent
      ownerHint = metadata.label ?? metadata.program
    } else if [.privilegedHelper, .systemExtension].contains(category) {
      let signature = signatureDetails(for: url)
      teamIdentifier = signature.teamIdentifier
      signatureStatus = signature.status
      ownerHint = teamIdentifier ?? url.lastPathComponent
    } else {
      ownerHint = ownerFromName(url.lastPathComponent)
    }

    let standardizedPath = url.standardizedFileURL.path
    return SnapshotItem(
      id: "\(category.rawValue)|\(standardizedPath)",
      category: category,
      name: name,
      path: standardizedPath,
      size: Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0),
      modifiedAt: values.contentModificationDate,
      bundleIdentifier: bundleIdentifier,
      version: version,
      teamIdentifier: teamIdentifier,
      signatureStatus: signatureStatus,
      ownerHint: ownerHint
    )
  }

  private func propertyListMetadata(at url: URL) -> (label: String?, program: String?) {
    guard
      let data = try? Data(contentsOf: url),
      let object = try? PropertyListSerialization.propertyList(from: data, format: nil),
      let dictionary = object as? [String: Any]
    else { return (nil, nil) }

    let arguments = dictionary["ProgramArguments"] as? [String]
    return (
      dictionary["Label"] as? String,
      dictionary["Program"] as? String ?? arguments?.first
    )
  }

  private func signatureDetails(for url: URL) -> (status: String?, teamIdentifier: String?) {
    var staticCode: SecStaticCode?
    guard SecStaticCodeCreateWithPath(url as CFURL, [], &staticCode) == errSecSuccess,
      let staticCode
    else { return (nil, nil) }

    let valid = SecStaticCodeCheckValidity(staticCode, [], nil) == errSecSuccess
    var information: CFDictionary?
    let flags = SecCSFlags(rawValue: kSecCSSigningInformation)
    guard SecCodeCopySigningInformation(staticCode, flags, &information) == errSecSuccess,
      let dictionary = information as? [String: Any]
    else { return (valid ? "Hợp lệ" : "Không hợp lệ", nil) }

    return (
      valid ? "Hợp lệ" : "Không hợp lệ",
      dictionary[kSecCodeInfoTeamIdentifier as String] as? String
    )
  }

  private func ownerFromName(_ name: String) -> String? {
    let cleaned = name.replacingOccurrences(of: ".plist", with: "")
    let parts = cleaned.split(separator: ".")
    guard parts.count >= 3 else { return cleaned.isEmpty ? nil : cleaned }
    return parts.prefix(3).joined(separator: ".")
  }
}

private struct ScanOutcome {
  var items: [SnapshotItem] = []
  var inaccessiblePaths: [String] = []
  var truncated = false
}
