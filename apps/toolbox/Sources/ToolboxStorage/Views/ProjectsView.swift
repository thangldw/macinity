import AppKit
import SwiftUI
import ToolboxCore

private enum ProjectSafetyFilter: String, CaseIterable, Identifiable {
  case all = "Tất cả"
  case safe = "An toàn"
  case review = "Cần xem lại"
  case protected = "Được bảo vệ"

  var id: String { rawValue }
}

struct ProjectsView: View {
  @StateObject private var model = ProjectViewModel()
  @State private var ecosystem: ProjectEcosystem?
  @State private var safetyFilter = ProjectSafetyFilter.all
  @State private var searchText = ""
  @State private var showsCleanupConfirmation = false

  private var filteredArtifacts: [ProjectArtifact] {
    (model.report?.artifacts ?? []).filter { artifact in
      let matchesEcosystem = ecosystem == nil || artifact.ecosystem == ecosystem
      let matchesSafety: Bool =
        switch safetyFilter {
        case .all: true
        case .safe: artifact.safety == .safe
        case .review: artifact.safety == .review
        case .protected: artifact.safety == .protected
        }
      let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      let matchesSearch =
        query.isEmpty || artifact.artifactURL.path.localizedCaseInsensitiveContains(query)
      return matchesEcosystem && matchesSafety && matchesSearch
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Dự án",
        subtitle: "Artifact có thể tạo lại, chỉ trong project root bạn chọn",
        symbol: "hammer",
        value: ByteCount.string(model.report?.reclaimableBytes ?? 0),
        valueLabel: "có thể xem xét")
      Divider()

      if model.roots.isEmpty {
        emptyState
      } else {
        projectContent
      }

      Divider()
      bottomBar
    }
    .alert("Chuyển artifact đã chọn vào Trash?", isPresented: $showsCleanupConfirmation) {
      Button("Hủy", role: .cancel) {}
      Button("Chuyển vào Trash", role: .destructive) { model.cleanSelected() }
    } message: {
      Text(
        "\(model.selectedArtifacts.count) artifact • \(ByteCount.string(model.selectedBytes)). Project source, manifest, lockfile và .git không được chọn."
      )
    }
    .alert(
      "Toolbox",
      isPresented: Binding(
        get: { model.errorMessage != nil },
        set: { if !$0 { model.errorMessage = nil } })
    ) {
      Button("Đóng", role: .cancel) { model.errorMessage = nil }
    } message: {
      Text(model.errorMessage ?? "")
    }
  }

  private var emptyState: some View {
    VStack(spacing: 16) {
      EmptyStateView(
        title: "Chưa chọn project root", symbol: "folder.badge.plus",
        detail:
          "Toolbox chỉ quét thư mục bạn chọn và chỉ đề xuất artifact có marker hệ sinh thái rõ ràng."
      )
      Button("Chọn project…") { chooseProjects() }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut("o", modifiers: [.command])
      Spacer(minLength: 30)
    }
  }

  private var projectContent: some View {
    VStack(spacing: 0) {
      rootsBar
      filters
      Divider()
      if filteredArtifacts.isEmpty {
        EmptyStateView(
          title: model.report == nil ? "Sẵn sàng quét" : "Không có artifact phù hợp",
          symbol: model.report == nil ? "magnifyingglass" : "checkmark.shield",
          detail: model.report == nil
            ? "Toolbox sẽ nhận diện output có thể tạo lại từ marker dự án."
            : "Không có source, manifest, lockfile hoặc thư mục chưa biết nào được đề xuất.")
      } else {
        List(filteredArtifacts) { artifact in
          artifactRow(artifact)
        }
        .listStyle(.inset)
      }
    }
  }

  private var rootsBar: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(model.roots, id: \.path) { root in
          HStack(spacing: 6) {
            Image(systemName: "folder")
            Text(root.path).lineLimit(1).truncationMode(.middle).textSelection(.enabled)
            Button {
              model.removeRoot(root)
            } label: {
              Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Bỏ project \(root.lastPathComponent)")
          }
          .font(.caption)
          .padding(.horizontal, 10)
          .padding(.vertical, 7)
          .background(.regularMaterial, in: Capsule())
        }
      }
      .padding(.horizontal, 18)
      .padding(.vertical, 10)
    }
  }

  private var filters: some View {
    HStack {
      Picker("Hệ sinh thái", selection: $ecosystem) {
        Text("Tất cả hệ sinh thái").tag(Optional<ProjectEcosystem>.none)
        ForEach(ProjectEcosystem.allCases) { value in
          Text(value.rawValue).tag(Optional(value))
        }
      }
      .frame(maxWidth: 190)
      Picker("Mức an toàn", selection: $safetyFilter) {
        ForEach(ProjectSafetyFilter.allCases) { value in
          Text(value.rawValue).tag(value)
        }
      }
      .frame(maxWidth: 180)
      TextField("Tìm đường dẫn", text: $searchText)
        .textFieldStyle(.roundedBorder)
        .frame(maxWidth: 260)
      Spacer()
    }
    .padding(.horizontal, 18)
    .padding(.bottom, 10)
  }

  private func artifactRow(_ artifact: ProjectArtifact) -> some View {
    HStack(spacing: 12) {
      Toggle(
        "",
        isOn: Binding(
          get: { model.selectedIDs.contains(artifact.id) },
          set: { selected in
            if selected {
              model.selectedIDs.insert(artifact.id)
            } else {
              model.selectedIDs.remove(artifact.id)
            }
          })
      )
      .labelsHidden()
      .disabled(artifact.safety != .safe || model.isWorking)

      Image(systemName: safetySymbol(artifact.safety))
        .foregroundStyle(safetyColor(artifact.safety))
        .accessibilityLabel(safetyFilterLabel(artifact.safety))
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(artifact.artifactURL.lastPathComponent).fontWeight(.semibold)
          Text(artifact.ecosystem.rawValue)
            .font(.caption)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(.quaternary, in: Capsule())
        }
        Text(artifact.artifactURL.path)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .truncationMode(.middle)
          .textSelection(.enabled)
        if let reason = artifact.reasons.first {
          Text(L10n.text(reason)).font(.caption2).foregroundStyle(.secondary)
        }
      }
      Spacer()
      Text(ByteCount.string(artifact.bytes)).monospacedDigit()
      Button("Finder") { NSWorkspace.shared.activateFileViewerSelecting([artifact.artifactURL]) }
    }
    .padding(.vertical, 6)
  }

  private var bottomBar: some View {
    HStack {
      Text(L10n.text(model.status)).foregroundStyle(.secondary).lineLimit(1)
      Spacer()
      Button("Thêm project…") { chooseProjects() }
      if model.isWorking {
        Button("Hủy") { model.cancel() }
          .keyboardShortcut(.cancelAction)
      } else {
        Button("Quét") { model.scan() }
          .keyboardShortcut("r", modifiers: [.command])
          .disabled(model.roots.isEmpty)
      }
      Button("Chuyển vào Trash…") { showsCleanupConfirmation = true }
        .buttonStyle(.borderedProminent)
        .disabled(model.selectedArtifacts.isEmpty || model.isWorking)
    }
    .padding(18)
  }

  private func chooseProjects() {
    let panel = NSOpenPanel()
    panel.title = "Chọn project root"
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = true
    panel.resolvesAliases = true
    if panel.runModal() == .OK {
      model.addRoots(panel.urls)
      model.scan()
    }
  }

  private func safetySymbol(_ safety: SafetyLevel) -> String {
    switch safety {
    case .safe: "checkmark.shield.fill"
    case .review: "eye.circle.fill"
    case .protected: "lock.shield.fill"
    }
  }

  private func safetyColor(_ safety: SafetyLevel) -> Color {
    switch safety {
    case .safe: .green
    case .review: .orange
    case .protected: .red
    }
  }

  private func safetyFilterLabel(_ safety: SafetyLevel) -> String {
    switch safety {
    case .safe: "An toàn"
    case .review: "Cần xem lại"
    case .protected: "Được bảo vệ"
    }
  }
}
