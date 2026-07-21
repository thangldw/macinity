import SwiftUI

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
              colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
        Image(systemName: symbol).font(.system(size: 28, weight: .semibold)).foregroundStyle(.white)
      }
      .frame(width: 60, height: 60)
      VStack(alignment: .leading, spacing: 4) {
        Text(title).font(.system(size: 27, weight: .bold))
        Text(subtitle).foregroundStyle(.secondary).lineLimit(2)
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
  var color: Color = .purple

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: symbol).font(.title2).foregroundStyle(color)
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

struct RiskBadge: View {
  let risk: ChangeRisk

  private var color: Color {
    switch risk {
    case .informational: .secondary
    case .review: .orange
    case .important: .red
    }
  }

  var body: some View {
    Label(risk.title, systemImage: risk.symbol)
      .font(.caption)
      .foregroundStyle(color)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(color.opacity(0.1), in: Capsule())
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
      Text(detail).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 460)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(30)
  }
}

enum ChangeoraFormat {
  static func bytes(_ bytes: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
  }

  static func duration(from start: Date, to end: Date = Date()) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .abbreviated
    return formatter.string(from: max(0, end.timeIntervalSince(start))) ?? "—"
  }
}
