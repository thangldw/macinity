import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
  case english = "en"
  case vietnamese = "vi"

  static let storageKey = "preferredAppLanguage"
  var id: String { rawValue }
  var title: String { self == .english ? "English" : "Tiếng Việt" }
  var locale: Locale { Locale(identifier: rawValue) }
}

enum L10n {
  private static let phraseKeys = [
    "Application bundle thay đổi; kiểm tra version, Team ID và chữ ký.",
    "Kernel extension tác động ở mức hệ thống và cần được xem xét cẩn thận.",
    "LaunchDaemon mới có thể chạy nền với quyền hệ thống/root.",
    "Thành phần persistence có thể tự chạy khi đăng nhập hoặc trong nền.",
    "Thành phần đặc quyền hoặc system extension có thể chạy ngoài tiến trình ứng dụng.",
    "Không thể", "Đã phát hiện", "Đã lưu", "Đã hủy", "Đang chụp", "Không phát hiện",
    "thay đổi", "phiên", "mục", "đường dẫn", "trong phạm vi theo dõi", "từ snapshot và",
    "FSEvent", "Baseline có", "So sánh hai phiên có",
  ].sorted { $0.count > $1.count }

  static var language: AppLanguage {
    AppLanguage(rawValue: UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? "en")
      ?? .english
  }

  static func text(_ key: String) -> String {
    guard language == .english,
      let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
      let bundle = Bundle(path: path)
    else { return key }
    let exact = bundle.localizedString(forKey: key, value: key, table: nil)
    if exact != key { return exact }
    return phraseKeys.reduce(key) { result, phrase in
      let translation = bundle.localizedString(forKey: phrase, value: phrase, table: nil)
      return translation == phrase
        ? result : result.replacingOccurrences(of: phrase, with: translation)
    }
  }
}

struct LanguagePicker: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue

  var body: some View {
    Picker("Language / Ngôn ngữ", selection: $languageCode) {
      ForEach(AppLanguage.allCases) { language in
        Text(language.title).tag(language.rawValue)
      }
    }
    .pickerStyle(.menu)
    .accessibilityLabel("Language / Ngôn ngữ")
  }
}
