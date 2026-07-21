import SwiftUI

struct CoverageView: View {
  @ObservedObject var model: ChangeoraViewModel

  private var categoryCounts: [(SnapshotCategory, Int)] {
    let items = model.currentSnapshot?.items ?? []
    return SnapshotCategory.allCases.map { category in
      (category, items.count { $0.category == category })
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Phạm vi & quyền riêng tư",
        subtitle: "Minh bạch về dữ liệu Changeora đọc, lưu và không thể quan sát.",
        symbol: "hand.raised",
        value: "Local",
        valueLabel: "không telemetry"
      )
      Divider()
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          monitoredCategories
          limitations
          if let snapshot = model.currentSnapshot, !snapshot.inaccessiblePaths.isEmpty {
            inaccessible(snapshot)
          }
        }
        .padding(24)
      }
    }
  }

  private var monitoredCategories: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(
        model.activeSnapshot == nil ? "Mục thay đổi trong phiên gần nhất" : "Snapshot đang theo dõi"
      )
      .font(.title2).fontWeight(.semibold)
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 210))], spacing: 12) {
        ForEach(categoryCounts, id: \.0.id) { category, count in
          MetricCard(title: category.rawValue, value: "\(count)", symbol: category.symbol)
        }
      }
    }
  }

  private var limitations: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Nguyên tắc an toàn").font(.title2).fontWeight(.semibold)
      Label(
        "Chỉ đọc metadata như đường dẫn, thời gian, kích thước, Bundle ID và chữ ký.",
        systemImage: "doc.text.magnifyingglass")
      Label(
        "Không đọc nội dung tài liệu cá nhân và không gửi dữ liệu ra mạng.",
        systemImage: "network.slash")
      Label("Không tự xóa, tắt service hoặc sửa System Settings.", systemImage: "hand.raised.slash")
      Label(
        "Một số vùng được macOS bảo vệ có thể cần Full Disk Access để quan sát đầy đủ.",
        systemImage: "lock")
      Label(
        "Changeora đưa ra bằng chứng kỹ thuật, không kết luận một ứng dụng là độc hại.",
        systemImage: "exclamationmark.bubble")
    }
    .foregroundStyle(.secondary)
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
  }

  private func inaccessible(_ snapshot: SystemSnapshot) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Không thể đọc").font(.title2).fontWeight(.semibold)
      ForEach(snapshot.inaccessiblePaths.prefix(20), id: \.self) { path in
        Text(path).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
      }
      if snapshot.inaccessiblePaths.count > 20 {
        Text("…và \(snapshot.inaccessiblePaths.count - 20) đường dẫn khác")
          .font(.caption).foregroundStyle(.secondary)
      }
    }
  }
}
