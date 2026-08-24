import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
  case english = "en"
  case vietnamese = "vi"

  public static let storageKey = "toolbox.appLanguage"
  public static let defaultLanguage = AppLanguage.english

  public var id: String { rawValue }
  public var locale: Locale { Locale(identifier: rawValue) }
  public var displayName: String {
    switch self {
    case .english: "English"
    case .vietnamese: "Tiếng Việt"
    }
  }
}

public enum L10n {
  public static func text(_ source: String) -> String {
    Bundle.main.localizedString(forKey: source, value: source, table: nil)
  }
}

public enum ByteCount {
  public static func string(_ bytes: Int64) -> String {
    guard bytes > 0 else { return "0 KB" }
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
    formatter.countStyle = .file
    formatter.includesUnit = true
    formatter.isAdaptive = true
    return formatter.string(fromByteCount: bytes)
  }
}
