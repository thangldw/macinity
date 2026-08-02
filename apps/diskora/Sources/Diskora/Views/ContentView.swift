import SwiftUI

private enum AppSection: String, CaseIterable, Identifiable {
  case cleanup = "Dọn nhanh"
  case analyzer = "Phân tích dung lượng"
  case duplicates = "Tệp trùng lặp"
  case similarPhotos = "Ảnh tương tự"
  case deepClean = "Dọn chuyên sâu"
  case applications = "Gỡ ứng dụng"
  case developer = "Developer"
  case schedule = "Lịch quét"
  case history = "Lịch sử"

  var id: String { rawValue }
  var title: String { L10n.text(rawValue) }
  var symbol: String {
    switch self {
    case .cleanup: return "sparkles"
    case .analyzer: return "internaldrive"
    case .duplicates: return "doc.on.doc"
    case .similarPhotos: return "photo.stack"
    case .deepClean: return "sparkles.rectangle.stack"
    case .applications: return "app.badge"
    case .developer: return "hammer"
    case .schedule: return "calendar.badge.clock"
    case .history: return "clock.arrow.circlepath"
    }
  }
}

struct ContentView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
  @State private var selection: AppSection? = .cleanup
  @StateObject private var cleaner = CleanerViewModel()
  @StateObject private var analyzer = AnalyzerViewModel()
  @StateObject private var duplicates = DuplicateViewModel()
  @StateObject private var similarPhotos = SimilarPhotoViewModel()
  @StateObject private var deepClean = DeepCleanViewModel()
  @StateObject private var applications = ApplicationViewModel()
  @StateObject private var history = HistoryViewModel()

  var body: some View {
    NavigationSplitView {
      List(AppSection.allCases, selection: $selection) { section in
        Label(section.title, systemImage: section.symbol)
          .tag(section)
      }
      .navigationTitle("Diskora")
      .navigationSplitViewColumnWidth(min: 190, ideal: 220)
      .safeAreaInset(edge: .bottom) {
        LanguagePicker().padding(.horizontal, 12).padding(.vertical, 8)
      }
    } detail: {
      switch selection ?? .cleanup {
      case .cleanup:
        QuickCleanView(model: cleaner)
      case .analyzer:
        StorageAnalyzerView(model: analyzer)
      case .duplicates:
        DuplicateFilesView(model: duplicates)
      case .similarPhotos:
        SimilarPhotosView(model: similarPhotos)
      case .deepClean:
        DeepCleanView(model: deepClean)
      case .applications:
        ApplicationsView(model: applications)
      case .developer:
        DeveloperStorageView(model: analyzer)
      case .schedule:
        ScheduledScanView()
      case .history:
        HistoryView(model: history)
      }
    }
    .environment(\.locale, AppLanguage(rawValue: languageCode)?.locale ?? .init(identifier: "en"))
    .id(languageCode)
    .frame(minWidth: 940, minHeight: 650)
  }
}
