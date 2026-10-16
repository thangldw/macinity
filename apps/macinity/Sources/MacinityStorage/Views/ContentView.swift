import AppKit
import MacinityCore
import SwiftUI

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
  private let focusPath: String?
  private let applicationActivity: ((URL) -> AnyView)?
  @State private var workspaceSection: StorageWorkspaceSection = .cleanup
  @StateObject private var cleaner = CleanerViewModel()
  @StateObject private var analyzer = AnalyzerViewModel()
  @StateObject private var duplicates = DuplicateViewModel()
  @StateObject private var similarPhotos = SimilarPhotoViewModel()
  @StateObject private var deepClean = DeepCleanViewModel()
  @StateObject private var applications = ApplicationViewModel()
  @StateObject private var history = HistoryViewModel()

  public init(
    destination: StorageDestination, focusPath: String? = nil,
    applicationActivity: ((URL) -> AnyView)? = nil
  ) {
    self.destination = destination
    self.focusPath = focusPath
    self.applicationActivity = applicationActivity
  }

  public var body: some View {
    destinationView
  }

  @ViewBuilder
  private var destinationView: some View {
    switch destination {
    case .storage:
      VStack(spacing: 0) {
        if let focusPath {
          HStack(spacing: 10) {
            Label(L10n.text("Evidence path"), systemImage: "scope")
              .fontWeight(.semibold)
            Text(focusPath)
              .font(.caption.monospaced())
              .lineLimit(1)
              .truncationMode(.middle)
              .textSelection(.enabled)
            Spacer()
            Text(L10n.text("Not selected or cleaned automatically."))
              .font(.caption)
              .foregroundStyle(.secondary)
            Button(L10n.text("Show in Finder")) {
              NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: focusPath)])
            }
          }
          .padding(.horizontal, 18)
          .padding(.vertical, 10)
          .background(Color.orange.opacity(0.08))
        }
        MacinityChoicePicker(
          L10n.text("Công cụ lưu trữ"), selection: $workspaceSection,
          options: StorageWorkspaceSection.allCases.map { ($0, $0.title) }, minimumWidth: 140
        )
        .padding()

        Divider()
        storageWorkspace
      }
      .onAppear {
        if focusPath != nil { workspaceSection = .analyzer }
      }
    case .projects:
      ProjectsView()
    case .applications:
      ApplicationsView(model: applications, applicationActivity: applicationActivity)
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
