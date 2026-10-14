import Foundation

public enum AppMetadata {
  // Legacy storage namespace remains stable across display-name changes.
  public static let name = "Toolbox"
  public static var displayName: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Orven"
  }
  public static let tagline = "Understand your Mac. Act with context."
  public static let bundleIdentifier = "com.thang.toolbox"

  public static var version: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "3.0.0"
  }

  public static var build: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "300"
  }

  public static func applicationSupportDirectory(base: URL? = nil) -> URL {
    let root =
      base
      ?? FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let directory = root.appendingPathComponent(name, isDirectory: true)
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }
}
