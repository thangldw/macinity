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
  private static let phraseKeys = [
    "Application bundle thay đổi; kiểm tra version, Team ID và chữ ký.",
    "Kernel extension tác động ở mức hệ thống và cần được xem xét cẩn thận.",
    "LaunchDaemon mới có thể chạy nền với quyền hệ thống/root.",
    "Thành phần persistence có thể tự chạy khi đăng nhập hoặc trong nền.",
    "Thành phần đặc quyền hoặc system extension có thể chạy ngoài tiến trình ứng dụng.",
    "Toolbox chỉ nhận .dmg, .pkg hoặc .app", "Install Trace đã lưu",
    "Không thể", "Đã phát hiện", "Đã chuyển", "Đã khôi phục", "Đã quét xong", "Đã quét",
    "Đã xử lý", "Đã bật", "Đã tắt", "Đã chọn", "Đã lưu", "Đã hủy", "Đang chụp",
    "Đang phân tích", "Đang chạy", "Không phát hiện", "Tìm thấy", "Có thể giải phóng",
    "Có thể xem xét", "mục vào Trash", "tệp vào Trash", "vào Trash", "thay đổi", "phiên",
    "tệp", "mục", "nhóm", "ảnh", "giờ", "đường dẫn", "không có", "thất bại", "hoàn tất",
    "đường dẫn không an toàn", "vị trí gốc đã có dữ liệu", "dự án",
    "không còn trong Trash", "nội dung đã thay đổi, thao tác bị hủy",
  ].sorted { $0.count > $1.count }

  public static func text(_ source: String) -> String {
    let language =
      AppLanguage(
        rawValue: UserDefaults.standard.string(forKey: AppLanguage.storageKey)
          ?? AppLanguage.defaultLanguage.rawValue)
      ?? AppLanguage.defaultLanguage
    guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
      let bundle = Bundle(path: path)
    else { return source }

    for table in ["Localizable", "Storage", "Changes"] {
      let localized = bundle.localizedString(forKey: source, value: source, table: table)
      if localized != source { return localized }
    }

    guard language == .english else { return source }
    return phraseKeys.reduce(source) { result, phrase in
      for table in ["Storage", "Changes"] {
        let translation = bundle.localizedString(forKey: phrase, value: phrase, table: table)
        if translation != phrase {
          return result.replacingOccurrences(of: phrase, with: translation)
        }
      }
      return result
    }
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
