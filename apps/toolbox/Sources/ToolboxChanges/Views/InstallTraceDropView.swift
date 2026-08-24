import AppKit
import SwiftUI
import ToolboxCore

struct InstallTraceDropView: View {
  @ObservedObject var model: ChangeoraViewModel
  @StateObject private var coordinator = InstallTraceCoordinator()
  @State private var selectedInstaller: InstallerMetadata?
  @State private var sessionTitle = ""
  @State private var isDropTargeted = false
  @State private var errorMessage: String?
  @State private var latestSession: WatchSession?

  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Install Trace",
        subtitle: "Thả installer, chụp trước/sau và xem bằng chứng thay đổi",
        symbol: "scope",
        value: "\(model.sessions.count)",
        valueLabel: "phiên đã lưu")
      Divider()

      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          switch coordinator.recoveryState {
          case .interrupted:
            interruptedCard
          case .none:
            if coordinator.activeMetadata != nil {
              activeTraceCard
            } else {
              dropZone
              if let selectedInstaller { installerCard(selectedInstaller) }
            }
          }

          if coordinator.isWorking {
            HStack(spacing: 10) {
              ProgressView().controlSize(.small)
              Text(L10n.text(coordinator.statusMessage ?? "Đang quét…"))
                .foregroundStyle(.secondary)
            }
          } else if let status = coordinator.statusMessage {
            Label(L10n.text(status), systemImage: "checkmark.circle")
              .foregroundStyle(.secondary)
          }

          if let session = latestSession ?? model.sessions.first {
            resultCard(session)
          }

          privacyCard
        }
        .padding(24)
        .frame(maxWidth: 900, alignment: .leading)
      }
    }
    .alert(
      "Toolbox",
      isPresented: Binding(
        get: { errorMessage != nil },
        set: { if !$0 { errorMessage = nil } })
    ) {
      Button("Đóng", role: .cancel) { errorMessage = nil }
    } message: {
      Text(L10n.text(errorMessage ?? ""))
    }
    .onAppear {
      selectedInstaller = coordinator.activeMetadata
      if sessionTitle.isEmpty { sessionTitle = coordinator.activeMetadata?.displayName ?? "" }
    }
  }

  private var dropZone: some View {
    VStack(spacing: 14) {
      Image(systemName: isDropTargeted ? "arrow.down.doc.fill" : "shippingbox")
        .font(.system(size: 42, weight: .medium))
        .foregroundStyle(isDropTargeted ? Color.accentColor : Color.secondary)
      Text("Thả .dmg, .pkg hoặc .app vào đây")
        .font(.title2.weight(.semibold))
      Text("Toolbox chỉ đọc loại file và đường dẫn; installer chỉ mở sau khi baseline đã lưu.")
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      Button("Chọn installer…") { chooseInstaller() }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut("o", modifiers: [.command])
    }
    .padding(34)
    .frame(maxWidth: .infinity, minHeight: 230)
    .background(
      isDropTargeted ? Color.accentColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor),
      in: RoundedRectangle(cornerRadius: 16)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 16)
        .strokeBorder(
          isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
          style: StrokeStyle(lineWidth: 2, dash: [7]))
    }
    .dropDestination(for: URL.self) { urls, _ in
      guard let url = urls.first else { return false }
      return accept(url)
    } isTargeted: {
      isDropTargeted = $0
    }
  }

  private func installerCard(_ metadata: InstallerMetadata) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 12) {
        Image(systemName: "doc.badge.gearshape")
          .font(.title2)
          .foregroundStyle(.purple)
        VStack(alignment: .leading, spacing: 3) {
          Text(metadata.displayName).font(.title3.weight(.semibold))
          Text("\(metadata.kind.displayName) • \(metadata.sourceURL.path)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .textSelection(.enabled)
        }
        Spacer()
        Button("Bỏ chọn") { selectedInstaller = nil }
      }
      TextField("Tên phiên", text: $sessionTitle)
        .textFieldStyle(.roundedBorder)
        .frame(maxWidth: 500)
      Button {
        start(metadata)
      } label: {
        Label("Lưu baseline và mở installer", systemImage: "play.circle.fill")
      }
      .buttonStyle(.borderedProminent)
      .keyboardShortcut(.return, modifiers: [.command])
      .disabled(coordinator.isWorking)
    }
    .padding(20)
    .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
  }

  private var activeTraceCard: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Label("Đang theo dõi installer", systemImage: "dot.radiowaves.left.and.right")
          .font(.title2.weight(.semibold))
          .foregroundStyle(.purple)
        Spacer()
        if let startedAt = coordinator.startedAt {
          TimelineView(.periodic(from: .now, by: 1)) { _ in
            Text(ChangeoraFormat.duration(from: startedAt))
              .monospacedDigit()
              .foregroundStyle(.secondary)
          }
        }
      }
      if let metadata = coordinator.activeMetadata {
        Text("\(metadata.kind.displayName) • \(metadata.sourceURL.path)")
          .font(.caption)
          .foregroundStyle(.secondary)
          .textSelection(.enabled)
      }
      if coordinator.reducedCoverage {
        Label(
          "Coverage giảm vì Toolbox không chạy trong một phần của phiên.",
          systemImage: "exclamationmark.triangle"
        )
        .foregroundStyle(.orange)
      }
      TextField("Tên phiên", text: $sessionTitle)
        .textFieldStyle(.roundedBorder)
        .frame(maxWidth: 500)
      HStack {
        Button {
          finish()
        } label: {
          Label("Hoàn tất và so sánh", systemImage: "checkmark.circle.fill")
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.return, modifiers: [.command])
        Button("Hủy phiên", role: .cancel) { cancel() }
          .keyboardShortcut(.cancelAction)
      }
      .disabled(coordinator.isWorking)
    }
    .padding(20)
    .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
  }

  private var interruptedCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("Install Trace bị gián đoạn", systemImage: "exclamationmark.triangle.fill")
        .font(.title2.weight(.semibold))
        .foregroundStyle(.orange)
      Text("Baseline vẫn còn nguyên. Có thể tiếp tục với coverage giảm hoặc bỏ phiên này.")
        .foregroundStyle(.secondary)
      HStack {
        Button("Tiếp tục với coverage giảm") {
          do {
            try coordinator.resumeInterruptedTrace()
            selectedInstaller = coordinator.activeMetadata
            sessionTitle = coordinator.activeMetadata?.displayName ?? "Install Trace khôi phục"
          } catch {
            errorMessage = error.localizedDescription
          }
        }
        .buttonStyle(.borderedProminent)
        Button("Bỏ phiên", role: .destructive) { cancel() }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
  }

  private func resultCard(_ session: WatchSession) -> some View {
    HStack(spacing: 12) {
      MetricCard(
        title: "Tổng thay đổi", value: "\(session.comparison.changes.count)",
        symbol: "arrow.left.arrow.right")
      MetricCard(
        title: "Quan trọng", value: "\(session.comparison.importantCount)",
        symbol: "exclamationmark.shield", color: .red)
      MetricCard(
        title: "Nên xem", value: "\(session.comparison.reviewCount)", symbol: "eye",
        color: .orange)
    }
  }

  private var privacyCard: some View {
    Label(
      "Snapshot và FSEvents chỉ lưu metadata cục bộ. Toolbox không mount, execute hoặc bypass Gatekeeper.",
      systemImage: "lock.shield"
    )
    .foregroundStyle(.secondary)
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
  }

  private func chooseInstaller() {
    let panel = NSOpenPanel()
    panel.title = "Chọn DMG, PKG hoặc ứng dụng"
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.treatsFilePackagesAsDirectories = false
    if panel.runModal() == .OK, let url = panel.url {
      _ = accept(url)
    }
  }

  private func accept(_ url: URL) -> Bool {
    do {
      let metadata = try coordinator.accept(url: url)
      selectedInstaller = metadata
      sessionTitle = metadata.displayName
      errorMessage = nil
      return true
    } catch {
      errorMessage = error.localizedDescription
      return false
    }
  }

  private func start(_ metadata: InstallerMetadata) {
    Task {
      do {
        try await coordinator.start(metadata: metadata)
        guard NSWorkspace.shared.open(metadata.sourceURL) else {
          throw CocoaError(.fileNoSuchFile)
        }
      } catch {
        errorMessage = error.localizedDescription
      }
    }
  }

  private func finish() {
    Task {
      do {
        latestSession = try await coordinator.finish(title: sessionTitle)
        model.reloadFromStore()
        selectedInstaller = nil
      } catch {
        errorMessage = error.localizedDescription
      }
    }
  }

  private func cancel() {
    do {
      try coordinator.cancel()
      model.reloadFromStore()
      selectedInstaller = nil
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
