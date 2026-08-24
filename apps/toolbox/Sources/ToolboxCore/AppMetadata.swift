import Foundation

public enum AppMetadata {
  public static let name = "Toolbox"
  public static let tagline = "See what changed. Reclaim space safely."
  public static let bundleIdentifier = "com.thang.toolbox"

  public static var version: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2.0.0"
  }

  public static var build: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
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
