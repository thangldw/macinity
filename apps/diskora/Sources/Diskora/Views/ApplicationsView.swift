import SwiftUI

struct ApplicationsView: View {
  @ObservedObject var model: ApplicationViewModel
  @State private var selected: InstalledApplication?
  @State private var includeLeftovers = true
  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Gỡ ứng dụng", subtitle: "Ứng dụng và dữ liệu còn sót", symbol: "app.badge",
        value: model.applications.count.formatted(), valueLabel: "ứng dụng")
      Divider()
      if model.applications.isEmpty {
        EmptyStateView(
          title: "Chưa quét ứng dụng", symbol: "app.badge",
          detail:
            "App sẽ tìm bundle trong Applications và đối chiếu Bundle ID với dữ liệu trong Library."
        )
      } else {
        List(model.applications) { app in
          DisclosureGroup {
            ForEach(app.leftovers) { item in
              HStack {
                Image(systemName: "doc.badge.gearshape")
                Text(item.url.path).lineLimit(1)
                Spacer()
                Text(ByteCount.string(item.bytes))
              }
            }
          } label: {
            HStack {
              Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path)).resizable().frame(
                width: 34, height: 34)
              VStack(alignment: .leading) {
                Text(app.name).fontWeight(.medium)
                Text(app.bundleIdentifier ?? "Không có Bundle ID").font(.caption).foregroundStyle(
                  .secondary)
              }
              Spacer()
              Text(ByteCount.string(app.totalBytes))
              Button("Gỡ…") { selected = app }
            }
          }.padding(.vertical, 4)
        }.listStyle(.inset)
      }
      Divider()
      HStack {
        if model.isWorking { ProgressView().controlSize(.small) }
        Text(model.status)
        Spacer()
        Button("Quét ứng dụng") { model.scan() }.disabled(model.isWorking)
      }.padding(18)
    }.alert(
      "Gỡ \(selected?.name ?? "ứng dụng")?",
      isPresented: Binding(get: { selected != nil }, set: { if !$0 { selected = nil } })
    ) {
      Toggle("Kèm dữ liệu còn sót", isOn: $includeLeftovers)
      Button("Hủy", role: .cancel) { selected = nil }
      Button("Chuyển vào Trash", role: .destructive) {
        if let selected { model.uninstall(selected, includeLeftovers: includeLeftovers) }
        selected = nil
      }
    } message: {
      Text(
        "Ứng dụng và dữ liệu đã chọn sẽ được chuyển vào Trash. Một số ứng dụng hệ thống có thể yêu cầu quyền quản trị."
      )
    }
  }
}
