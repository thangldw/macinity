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
    "Không thể", "Đã chuyển", "Đã khôi phục", "Đã quét xong", "Đã quét", "Đã xử lý", "Đã bật",
    "Đã tắt", "Đã chọn",
    "Đang phân tích", "Đang chạy", "Tìm thấy", "Có thể giải phóng", "Có thể xem xét",
    "mục vào Trash", "tệp vào Trash", "vào Trash", "tệp", "mục", "nhóm", "ảnh", "giờ",
    "không có", "thất bại", "hoàn tất", "đường dẫn không an toàn", "vị trí gốc đã có dữ liệu",
    "dự án",
    "không còn trong Trash", "nội dung đã thay đổi, thao tác bị hủy",
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
