import SwiftUI

struct WatchInstallationView: View {
  @ObservedObject var model: ChangeoraViewModel
  @State private var sessionTitle = "Cài đặt / cập nhật ứng dụng"

  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Theo dõi cài đặt",
        subtitle: "Chụp trạng thái trước và sau để biết ứng dụng đã thay đổi những gì.",
        symbol: "scope",
        value: "\(model.sessions.count)",
        valueLabel: "phiên đã lưu"
      )
      Divider()
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          if let active = model.activeSnapshot {
            activeSessionCard(active)
          } else {
            startCard
          }

          if model.isScanning {
            HStack(spacing: 10) {
              ProgressView().controlSize(.small)
              Text(model.statusMessage ?? "Đang quét…").foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
          } else if let message = model.statusMessage {
            Label(message, systemImage: "checkmark.circle")
              .foregroundStyle(.secondary)
              .padding(.horizontal, 4)
          }

          if let session = model.sessions.first {
            lastResult(session)
          }

          privacyNote
        }
        .padding(24)
      }
    }
  }

  private var startCard: some View {
    VStack(alignment: .leading, spacing: 14) {
      Label("Bắt đầu một phiên thay đổi", systemImage: "camera.metering.matrix")
        .font(.title2).fontWeight(.semibold)
      Text(
        "Changeora sẽ lưu snapshot ban đầu. Sau đó bạn cài hoặc cập nhật ứng dụng như bình thường và quay lại để so sánh."
      )
      .foregroundStyle(.secondary)
      TextField("Tên phiên", text: $sessionTitle)
        .textFieldStyle(.roundedBorder)
        .frame(maxWidth: 460)
      Button {
        model.startWatching()
      } label: {
        Label("Chụp trạng thái ban đầu", systemImage: "record.circle")
      }
      .buttonStyle(.borderedProminent)
      .disabled(model.isScanning)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
  }

  private func activeSessionCard(_ snapshot: SystemSnapshot) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Label("Đang theo dõi", systemImage: "dot.radiowaves.left.and.right")
          .font(.title2).fontWeight(.semibold).foregroundStyle(.purple)
        Spacer()
        Text(ChangeoraFormat.duration(from: snapshot.createdAt))
          .font(.system(.body, design: .monospaced)).foregroundStyle(.secondary)
      }
      Text(
        "Snapshot ban đầu có \(snapshot.items.count) mục. Hãy hoàn tất cài đặt hoặc cập nhật trước khi tạo snapshot thứ hai."
      )
      .foregroundStyle(.secondary)
      TextField("Tên phiên", text: $sessionTitle)
        .textFieldStyle(.roundedBorder)
        .frame(maxWidth: 460)
      HStack {
        Button {
          model.finishWatching(title: sessionTitle)
        } label: {
          Label("Hoàn tất và so sánh", systemImage: "checkmark.circle")
        }
        .buttonStyle(.borderedProminent)
        Button("Hủy phiên", role: .cancel) { model.cancelWatching() }
      }
      .disabled(model.isScanning)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
  }

  private func lastResult(_ session: WatchSession) -> some View {
    let comparison = session.comparison
    return VStack(alignment: .leading, spacing: 14) {
      HStack {
        VStack(alignment: .leading, spacing: 3) {
          Text("Kết quả gần nhất").font(.title2).fontWeight(.semibold)
          Text(session.title).foregroundStyle(.secondary)
        }
        Spacer()
        Text(session.finishedAt, style: .relative).foregroundStyle(.secondary)
      }
      HStack(spacing: 12) {
        MetricCard(
          title: "Tổng thay đổi", value: "\(comparison.changes.count)",
          symbol: "arrow.left.arrow.right")
        MetricCard(
          title: "Quan trọng", value: "\(comparison.importantCount)",
          symbol: "exclamationmark.shield", color: .red)
        MetricCard(
          title: "Nên xem", value: "\(comparison.reviewCount)", symbol: "eye", color: .orange)
      }
    }
  }

  private var privacyNote: some View {
    Label {
      Text(
        "Changeora chỉ đọc metadata cục bộ, không đọc nội dung tài liệu, không telemetry và không tự động xóa hoặc hoàn tác thay đổi."
      )
    } icon: {
      Image(systemName: "hand.raised.fill")
    }
    .foregroundStyle(.secondary)
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
  }
}
