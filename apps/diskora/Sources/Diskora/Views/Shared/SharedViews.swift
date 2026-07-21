import SwiftUI

struct TreemapView: View {
  let entries: [StorageEntry]
  private let colors: [Color] = [.blue, .cyan, .purple, .orange, .green, .pink, .indigo]
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Bản đồ dung lượng").font(.title2).fontWeight(.semibold)
      GeometryReader { geometry in
        let shown = Array(entries.prefix(12))
        let total = max(shown.reduce(Int64(0)) { $0 + $1.bytes }, 1)
        HStack(spacing: 3) {
          ForEach(Array(shown.enumerated()), id: \.element.id) { index, entry in
            let width = max(28, geometry.size.width * CGFloat(Double(entry.bytes) / Double(total)))
            ZStack(alignment: .bottomLeading) {
              RoundedRectangle(cornerRadius: 6).fill(colors[index % colors.count].gradient)
              VStack(alignment: .leading) {
                Text(entry.name).font(.caption).bold().lineLimit(1)
                Text(ByteCount.string(entry.bytes)).font(.caption2)
              }.foregroundStyle(.white).padding(6)
            }.frame(width: width)
          }
        }
      }.clipShape(RoundedRectangle(cornerRadius: 8))
    }
  }
}

struct PageHeader: View {
  let title: String
  let subtitle: String
  let symbol: String
  let value: String
  let valueLabel: String

  var body: some View {
    HStack(spacing: 16) {
      ZStack {
        RoundedRectangle(cornerRadius: 14)
          .fill(
            LinearGradient(
              colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
        Image(systemName: symbol).font(.system(size: 28, weight: .semibold)).foregroundStyle(.white)
      }
      .frame(width: 60, height: 60)
      VStack(alignment: .leading, spacing: 4) {
        Text(title).font(.system(size: 27, weight: .bold))
        Text(subtitle).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
      }
      Spacer()
      VStack(alignment: .trailing, spacing: 3) {
        Text(value).font(.system(size: 24, weight: .semibold, design: .rounded))
        Text(valueLabel).font(.caption).foregroundStyle(.secondary)
      }
    }
    .padding(24)
  }
}

struct MetricCard: View {
  let title: String
  let value: String
  let symbol: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: symbol).font(.title2).foregroundStyle(.blue)
      VStack(alignment: .leading, spacing: 2) {
        Text(value).font(.title3).fontWeight(.semibold)
        Text(title).font(.caption).foregroundStyle(.secondary)
      }
      Spacer()
    }
    .padding(14)
    .frame(maxWidth: .infinity)
    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
  }
}

struct EmptyStateView: View {
  let title: String
  let symbol: String
  let detail: String

  var body: some View {
    VStack(spacing: 12) {
      Spacer()
      Image(systemName: symbol).font(.system(size: 42)).foregroundStyle(.secondary)
      Text(title).font(.title2).fontWeight(.semibold)
      Text(detail).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 430)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(30)
  }
}
