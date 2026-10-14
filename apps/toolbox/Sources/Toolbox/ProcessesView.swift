import SwiftUI
import ToolboxCore
import ToolboxMonitoring

struct ProcessesView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @Environment(\.locale) private var locale
  @Environment(\.monitoringDisplayState) private var displayState
  @ObservedObject var model: MonitoringViewModel
  var focus: ProcessIdentity? = nil
  @State private var query = ""
  @State private var order = ProcessOrdering.cpu
  @State private var selection: ProcessRowID?
  @State private var showsCompactDetails = false
  @FocusState private var searchFocused: Bool

  private var samples: [ProcessSample] { model.snapshot?.processes.value ?? [] }
  private var rows: [ProcessSample] { order.sorted(samples, query: query) }
  private var selected: ProcessSample? { samples.first { $0.id == selection } }
  private var identity: ProcessIdentity? {
    guard case .verified(let identity) = selection else { return nil }
    return identity
  }

  var body: some View {
    GeometryReader { geometry in
      let sideBySide = geometry.size.width >= 900
      VStack(alignment: .leading, spacing: 18) {
        OrvenPageHeader(
          title: L10n.text("Processes"),
          subtitle: L10n.text("Inspect what's running on your Mac. Monitoring is read-only."))
        HStack(spacing: 16) {
          HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(L10n.text("Search processes or PID"), text: $query)
              .textFieldStyle(.plain).focused($searchFocused)
            Button {
              query = ""
              searchFocused = true
            } label: {
              Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain).accessibilityLabel(L10n.text("Clear search"))
            .disabled(query.isEmpty).opacity(query.isEmpty ? 0 : 1)
          }.padding(10).background(OrvenTheme.surface, in: RoundedRectangle(cornerRadius: 9))
            .overlay {
              RoundedRectangle(cornerRadius: 9).stroke(OrvenTheme.border, lineWidth: 1)
                .allowsHitTesting(false)
            }
          Picker(L10n.text("Sort by"), selection: $order) {
            Text(L10n.text("CPU")).tag(ProcessOrdering.cpu)
            Text(L10n.text("Memory")).tag(ProcessOrdering.memory)
            Text(L10n.text("Name")).tag(ProcessOrdering.name)
            Text("PID").tag(ProcessOrdering.pid)
          }.frame(width: 180)
        }
        HStack {
          Text(String(format: L10n.text("%d processes shown"), rows.count))
          Spacer()
          if !sideBySide, identity != nil {
            Button(L10n.text("Inspect process")) { showsCompactDetails = true }
          }
          if let reading = model.snapshot?.processes {
            Text(
              availabilityLabel(
                displayState.availability(
                  of: reading, at: ProcessInfo.processInfo.systemUptime, maximumAge: 6)))
            Text(reading.time.wall, style: .time)
          }
        }.font(.caption).foregroundStyle(OrvenTheme.secondary)
        if let reason = model.snapshot?.processes.reason { Text(reason).font(.caption) }
        HStack(alignment: .top, spacing: 18) {
          processTable.orvenSurface(padding: 0)
          if sideBySide, let identity {
            ScrollView { detail(identity: identity).padding(20) }
              .frame(width: 300).orvenSurface(padding: 0)
          }
        }.frame(maxHeight: .infinity)
        if identity == nil {
          Text(L10n.text("Select a process to inspect its verified identity and recent activity."))
            .font(.callout).foregroundStyle(OrvenTheme.secondary)
        }
        Text(
          L10n.text(
            "100% process CPU is one logical core. Restricted processes remain visible. No termination actions."
          )
        )
        .font(.caption).foregroundStyle(OrvenTheme.secondary)
      }.padding(28)
        .onChange(of: identity) { value in
          showsCompactDetails = value != nil && !sideBySide
        }
        .sheet(isPresented: $showsCompactDetails) {
          if let identity {
            ScrollView { detail(identity: identity).padding(24) }
              .frame(width: 440, height: 520).background(OrvenTheme.surface)
          }
        }
    }.background(OrvenTheme.canvas).environment(
      \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale
    )
    .task(id: focus) { if let focus { selection = .verified(focus) } }
    .task(id: identity) { await model.loadDetails(for: identity) }
  }

  private var processTable: some View {
    Table(rows, selection: $selection) {
      TableColumn(L10n.text("Name")) { Text($0.name).lineLimit(1).help($0.name) }
        .width(min: 130, ideal: 200)
      TableColumn("PID") { Text(String($0.pid)).monospacedDigit() }.width(60)
      TableColumn(L10n.text("CPU • one core")) { process in
        Text(
          process.cpu.value.map { monitoringNumber($0, digits: 1) + "%" }
            ?? availabilityLabel(process.cpu.availability)
        ).monospacedDigit()
      }.width(min: 110, ideal: 125)
      TableColumn(L10n.text("Resident memory")) { process in
        Text(
          process.memory.value.map { monitoringBytes($0) }
            ?? availabilityLabel(process.memory.availability)
        ).monospacedDigit()
      }.width(min: 110, ideal: 125)
    }
    .overlay {
      if rows.isEmpty {
        VStack(spacing: 10) {
          Image(systemName: "magnifyingglass").font(.title)
          Text(L10n.text(query.isEmpty ? "No process data available." : "No matching processes."))
        }.foregroundStyle(.secondary).allowsHitTesting(false)
      }
    }
  }

  private func detail(identity: ProcessIdentity) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        if let selected { OrvenProcessIcon(process: selected, size: 40) }
        Text(selected?.name ?? "PID \(identity.pid)").font(.title2.weight(.semibold))
        Spacer()
        Button {
          selection = nil
        } label: {
          Image(systemName: "xmark")
        }
        .buttonStyle(.plain).accessibilityLabel(L10n.text("Close details"))
        .keyboardShortcut(.cancelAction)
      }
      VStack(alignment: .leading, spacing: 8) {
        Text("PID " + String(identity.pid))
        Text(identity.startDate.formatted(.dateTime.day().month().year().locale(locale)))
        Text(identity.startDate.formatted(.dateTime.hour().minute().locale(locale)))
        if let parent = selected?.parentPID {
          Text(String(format: L10n.text("Observed parent PID: %d"), parent))
        }
      }.font(.caption).textSelection(.enabled)
      if selected == nil {
        if let reading = model.snapshot?.processes, reading.availability != .available {
          Text(availabilityLabel(reading.availability))
        } else {
          Text(L10n.text("Process exited or identity changed."))
        }
      } else if let details = model.details(for: identity), let selected {
        Text(
          availabilityLabel(
            details.availability == .available
              ? displayState.availability(
                of: selected.memory, at: ProcessInfo.processInfo.systemUptime, maximumAge: 6)
              : details.availability))
        if let threads = selected.threads {
          Text(String(format: L10n.text("Threads: %d"), threads))
        }
      } else {
        Text(L10n.text("Revalidating process identity…"))
      }
      if let selected, !selected.cpuHistory.isEmpty {
        MonitoringChart(
          title: L10n.text("Process CPU • one core"), unit: "%",
          data: selected.cpuHistory.map { ChartDatum(time: $0.time, value: $0.cpu) }, embedded: true
        )

      }
      ProcessPriorityView(identity: identity, name: selected?.name ?? "PID \(identity.pid)").id(
        identity)
      if model.applicationMapped(to: identity) {
        Button(L10n.text("Review in Applications")) { model.openMappedApplication(for: identity) }
          .buttonStyle(.borderedProminent)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
