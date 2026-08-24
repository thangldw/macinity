import SwiftUI
import ToolboxCore

public enum StorageDestination: String, CaseIterable, Sendable {
  case storage
  case projects
  case applications
  case recovery
}

private enum StorageWorkspaceSection: String, CaseIterable, Identifiable {
  case cleanup = "Dọn nhanh"
  case analyzer = "Phân tích dung lượng"
  case duplicates = "Tệp trùng lặp"
  case similarPhotos = "Ảnh tương tự"
  case deepClean = "Dọn chuyên sâu"
  case schedule = "Lịch quét"

  var id: String { rawValue }
  var title: String { L10n.text(rawValue) }
}

public struct StorageModuleSummary: Sendable, Equatable {
  public let recoverableBytes: Int64
  public let issueCount: Int

  public init(recoverableBytes: Int64, issueCount: Int) {
    self.recoverableBytes = recoverableBytes
    self.issueCount = issueCount
  }
}

public struct StorageModuleView: View {
  private let destination: StorageDestination
  @State private var workspaceSection: StorageWorkspaceSection = .cleanup
  @StateObject private var cleaner = CleanerViewModel()
  @StateObject private var analyzer = AnalyzerViewModel()
  @StateObject private var duplicates = DuplicateViewModel()
  @StateObject private var similarPhotos = SimilarPhotoViewModel()
  @StateObject private var deepClean = DeepCleanViewModel()
  @StateObject private var applications = ApplicationViewModel()
  @StateObject private var history = HistoryViewModel()

  public init(destination: StorageDestination) {
    self.destination = destination
  }

  public var body: some View {
    destinationView
  }

  @ViewBuilder
  private var destinationView: some View {
    switch destination {
    case .storage:
      VStack(spacing: 0) {
        Picker(L10n.text("Công cụ lưu trữ"), selection: $workspaceSection) {
          ForEach(StorageWorkspaceSection.allCases) { section in
            Text(section.title).tag(section)
          }
        }
        .pickerStyle(.segmented)
        .padding()

        Divider()
        storageWorkspace
      }
    case .projects:
      DeveloperStorageView(model: analyzer)
    case .applications:
      ApplicationsView(model: applications)
    case .recovery:
      HistoryView(model: history)
    }
  }

  @ViewBuilder
  private var storageWorkspace: some View {
    switch workspaceSection {
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
    case .schedule:
      ScheduledScanView()
    }
  }
}
