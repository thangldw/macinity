import MacinityCore
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
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  let title: String
  let subtitle: String
  let symbol: String
  let value: String
  let valueLabel: String

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: symbol).font(.system(size: 27, weight: .medium))
        .foregroundStyle(MacinityTheme.accent)
        .frame(width: 44, height: 44).accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 4) {
        Text(L10n.text(title)).font(.system(size: 30, weight: .bold)).foregroundStyle(
          MacinityTheme.ink)
        Text(L10n.text(subtitle)).foregroundStyle(.secondary).fixedSize(
          horizontal: false, vertical: true)
      }
      Spacer()
      VStack(alignment: .trailing, spacing: 3) {
        Text(value).font(.system(size: 24, weight: .semibold, design: .rounded))
        Text(L10n.text(valueLabel)).font(.caption).foregroundStyle(.secondary)
      }
    }
    .padding(24)
    .background(MacinityTheme.surface)
    .environment(
      \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale)
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
        Text(L10n.text(title)).font(.caption).foregroundStyle(.secondary)
      }
      Spacer()
    }
    .padding(14)
    .frame(maxWidth: .infinity)
    .background(MacinityTheme.surface, in: RoundedRectangle(cornerRadius: 10))
  }
}

struct EmptyStateView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  let title: String
  let symbol: String
  let detail: String

  var body: some View {
    VStack(spacing: 12) {
      Spacer()
      Image(systemName: symbol).font(.system(size: 42)).foregroundStyle(.secondary)
      Text(L10n.text(title)).font(.title2).fontWeight(.semibold)
        .fixedSize(horizontal: false, vertical: true)
      Text(L10n.text(detail)).foregroundStyle(.secondary).multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true).frame(
          maxWidth: 430)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(30)
    .environment(
      \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale)
  }
}
