import SwiftUI
import ToolboxCore
import ToolboxMonitoring

struct NetworkToolsView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @StateObject private var model = NetworkToolsViewModel()
  @ObservedObject var monitoring: MonitoringViewModel
  @State private var tab = "Network Overview"
  @State private var target = ""
  @State private var query = ""
  @FocusState private var searchFocused: Bool
  private var viewLocale: Locale {
    AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale
  }
  private let tabs = [
    "Network Overview", "Wi-Fi Inspector", "Ethernet Inspector", "Connection Diagnostics",
    "Latency & Stability", "Nearby Wi-Fi", "Saved Wi-Fi & Sharing", "Port & Service Inspector",
    "Network Change Timeline",
  ]
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        OrvenPageHeader(title: L10n.text("Wi-Fi & LAN"))
        OrvenSamplingStatus(model: monitoring)
        OrvenChoicePicker(
          L10n.text("Network tool"), selection: $tab,
          options: tabs.map { ($0, L10n.text($0)) }, minimumWidth: 150)
        HStack {
          Button(L10n.text("Refresh network status")) { model.refresh() }.disabled(
            model.busy != nil)
          if model.busy != nil {
            ProgressView().controlSize(.small)
            Button(L10n.text("Stop")) { model.cancel() }
          }
        }
        Text(L10n.text(model.status)).font(.callout).fixedSize(horizontal: false, vertical: true)
        if let overview = model.overview {
          HStack {
            Text(L10n.text("Last network observation"))
            Text(overview.observedAt, style: .time)
          }.font(.caption).foregroundStyle(.secondary)
        }
        switch tab {
        case "Wi-Fi Inspector": wifiPanel
        case "Ethernet Inspector": adapters(kind: "Ethernet")
        case "Connection Diagnostics", "Latency & Stability": measurements
        case "Saved Wi-Fi & Sharing": WiFiAccessView()
        case "Port & Service Inspector": PortInspectorView()
        case "Nearby Wi-Fi": nearby
        case "Network Change Timeline": timeline
        default: overviewPanel
        }
      }.padding(28)
    }
    .environment(
      \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale
    )
    .onAppear { model.appear() }
    .onDisappear { model.disappear() }
    .onChange(of: model.tracksChanges) { _ in model.resetTracking() }
  }
  private var overviewPanel: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 10) {
        Text(L10n.text(model.pathStatus)).font(.title2.bold())
        row(
          "Path interfaces",
          model.pathInterfaces.isEmpty ? L10n.text("Unavailable") : model.pathInterfaces)
        row("Low Data Mode", L10n.text(model.constrained ? "Yes" : "No"))
        row("Expensive path", L10n.text(model.expensive ? "Yes" : "No"))
        Text(
          L10n.text("An available path does not prove that an Internet destination is reachable.")
        ).font(.caption)
        Text(
          L10n.text(
            "Global DNS configuration is shown; scoped VPN and per-domain resolvers may differ.")
        ).font(.caption)
        if let value = model.overview {
          Divider()
          row("Primary interface", value.primary ?? L10n.text("Unavailable"))
          row("IPv4 gateway", value.gateway4 ?? L10n.text("Unavailable"))
          row("IPv6 gateway", value.gateway6 ?? L10n.text("Unavailable"))
          row(
            "DNS servers",
            value.dns.isEmpty ? L10n.text("Unavailable") : value.dns.joined(separator: ", "))
        }
      }.orvenSurface()
      adapters(kind: nil)
    }
  }
  @ViewBuilder private func adapters(kind: String?) -> some View {
    if let value = model.overview {
      let entries = value.adapters.filter { kind == nil || $0.kind == kind }
      if entries.isEmpty { Text(L10n.text("No matching network adapter was observed.")) }
      ForEach(entries) { adapter in
        VStack(alignment: .leading, spacing: 10) {
          HStack {
            Text(adapter.name + " • " + L10n.text(adapter.kind)).font(.headline)
            Spacer()
            Text(L10n.text(adapter.active ? "Up / running" : "Down / not running"))
          }
          row(
            "IP addresses",
            adapter.addresses.isEmpty
              ? L10n.text("Unavailable") : adapter.addresses.joined(separator: ", "))
          row("MTU", adapter.mtu > 0 ? String(adapter.mtu) : L10n.text("Unavailable"))
          if adapter.kind == "Ethernet" {
            row(
              "Carrier state",
              adapter.carrier.map {
                L10n.text(
                  $0 == "active"
                    ? "Link detected" : $0 == "inactive" ? "No link detected" : "Unknown")
              } ?? L10n.text("Unavailable"))
            row("Negotiated media", adapter.media ?? L10n.text("Unavailable"))
          }
          row("Received / sent bytes", number(adapter.received) + " / " + number(adapter.sent))
          row(
            "Input / output packets",
            number(adapter.inputPackets) + " / " + number(adapter.outputPackets))
          row(
            "Input / output errors",
            number(adapter.inputErrors) + " / " + number(adapter.outputErrors))
          row("Input queue drops", number(adapter.drops))
          if let rates = monitoring.snapshot?.hardware.interfaces.value,
            let rate = rates.first(where: { $0.name == adapter.name })
          {
            HStack {
              MetricReadout(
                title: L10n.text("Received"), sample: rate.input, format: rateText, maximumAge: 6)
              MetricReadout(
                title: L10n.text("Sent"), sample: rate.output, format: rateText, maximumAge: 6)
            }
          }
        }.orvenSurface()
      }
      Text(
        L10n.text(
          "Adapter counters are cumulative observations, not session traffic or Internet speed. Packet/error counters may wrap. Live rates reuse the existing sampler."
        )
      ).font(.caption).fixedSize(horizontal: false, vertical: true)
      if value.omittedAdapters > 0 {
        Text(
          String(
            format: L10n.text("%d adapters omitted by the display limit."), value.omittedAdapters))
      }
    } else {
      Text(L10n.text("Refresh to inspect Wi-Fi and LAN."))
    }
  }
  private var wifiIdentityPermission: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(
        L10n.text(
          "SSID and BSSID can be hidden by macOS location permissions. Missing identity does not mean Wi-Fi is disconnected."
        )
      ).font(.caption).fixedSize(horizontal: false, vertical: true)
      HStack {
        Button(L10n.text("Request Wi-Fi identity permission")) {
          model.requestWiFiIdentityPermission()
        }
        .disabled(model.locationStatus != "Not requested")
        Text(L10n.text(model.locationStatus))
      }
      Text(L10n.text("After allowing Location access, refresh or scan again to read Wi-Fi names."))
        .font(.caption).fixedSize(horizontal: false, vertical: true)
      if model.locationStatus == "Denied" || model.locationStatus == "Restricted" {
        Text(
          L10n.text(
            "Review Macinity in System Settings → Privacy & Security → Location Services. Restrictions may be managed by your organization."
          )
        )
        .font(.caption).fixedSize(horizontal: false, vertical: true)
      }
    }.orvenSurface()
  }
  private var wifiPanel: some View {
    VStack(alignment: .leading, spacing: 16) {
      wifiIdentityPermission
      if let value = model.overview {
        if value.wifi.isEmpty { Text(L10n.text("No Wi-Fi interface was observed.")) }
        ForEach(value.wifi, id: \.interface) { wifi in
          VStack(alignment: .leading, spacing: 10) {
            Text(wifi.interface).font(.headline)
            row("SSID", wifi.ssid ?? L10n.text("Unavailable or permission restricted"))
            row("BSSID", wifi.bssid ?? L10n.text("Unavailable or permission restricted"))
            row("RSSI", integer(wifi.rssi, unit: "dBm"))
            row("Noise", integer(wifi.noise, unit: "dBm"))
            row("SNR", integer(wifi.snr, unit: "dB"))
            row("Channel", integer(wifi.channel, unit: ""))
            row("Band", wifi.band.map { L10n.text($0) } ?? L10n.text("Unavailable"))
            row("Channel width", integer(wifi.widthMHz, unit: "MHz"))
            row(
              "Transmit link rate",
              wifi.transmitMbps.map {
                $0.formatted(.number.locale(viewLocale).precision(.fractionLength(1))) + " Mbps"
              } ?? L10n.text("Unavailable"))
          }.orvenSurface()
        }
      } else {
        Text(L10n.text("Refresh to inspect Wi-Fi and LAN."))
      }
      Text(
        L10n.text(
          "CoreWLAN reports local radio observations. Link rate is not measured Internet throughput; SNR is RSSI minus noise from this observation."
        )
      ).font(.caption).fixedSize(horizontal: false, vertical: true)
    }
  }
  private var measurements: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(L10n.text("Destination hostname or IP address")).font(.headline)
      TextField(L10n.text("Example: example.com or 192.168.1.1"), text: $target).textFieldStyle(
        .roundedBorder
      ).disabled(model.busy != nil)
      Text(
        L10n.text(
          "Measurements send traffic to the displayed destination. Connection diagnostics also tests the recently observed gateway, resolves the destination and opens TCP port 443. No payload or speed-test download is sent."
        )
      ).font(.caption).fixedSize(horizontal: false, vertical: true)
      HStack {
        if tab == "Connection Diagnostics" {
          Button(L10n.text("Check connection")) { model.diagnose(target) }.disabled(
            model.busy != nil || target.isEmpty)
        } else {
          Button(L10n.text("Measure 20 ICMP probes")) { model.measure(target) }.disabled(
            model.busy != nil || target.isEmpty)
        }
      }
      if tab == "Connection Diagnostics" {
        Text(
          L10n.text(
            "Refresh network status first to include a gateway observed within 60 seconds. Each stage is bounded; total connection check is at most 30 seconds."
          )
        ).font(.caption)
        ForEach(model.checks) { check in
          VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text(check.id)).font(.headline)
            row(
              "Destination", check.target == "Unavailable" ? L10n.text("Unavailable") : check.target
            )
            Text(L10n.text(check.detail))
            Text(check.observedAt, style: .time).font(.caption)
            if check.succeeded != nil {
              row(
                "Elapsed",
                check.durationMilliseconds.formatted(
                  .number.locale(viewLocale).precision(.fractionLength(1))) + " ms")
            }
          }.orvenSurface()
        }
        Text(
          L10n.text(
            "ICMP may be blocked while Internet access works. DNS results may be cached. A successful TCP connection does not verify HTTP, TLS, captive portals or every application."
          )
        ).font(.caption).fixedSize(horizontal: false, vertical: true)
      } else {
        Text(
          L10n.text(
            "20 probes, one second apart, at most 28 seconds. Loss uses the ICMP summary; jitter is the mean absolute difference between adjacent successful replies. Timeouts break the chart."
          )
        ).font(.caption).fixedSize(horizontal: false, vertical: true)
        if let value = model.latency {
          VStack(alignment: .leading, spacing: 10) {
            row("Destination", value.target)
            Text(value.observedAt, style: .time).font(.caption)
            row("Mean latency", decimal(value.meanMilliseconds, unit: "ms"))
            row("Jitter", decimal(value.jitterMilliseconds, unit: "ms"))
            row("Packet loss", decimal(value.lossPercent, unit: "%"))
            if value.exitStatus != 0 {
              Text(
                L10n.text(
                  "ICMP did not complete successfully; missing results are unknown or blocked."))
            }
          }.orvenSurface()
          MonitoringChart(
            title: L10n.text("ICMP round-trip latency"), unit: "ms",
            data: value.samples.map {
              ChartDatum(
                time: SampleTime(
                  wall: value.observedAt.addingTimeInterval(
                    Double($0.sequence - max(0, value.samples.count - 1))),
                  monotonic: Double($0.sequence)), value: $0.milliseconds)
            }, windowSeconds: 20, maximumGap: 1.5)
        }
      }
    }
  }
  private var nearby: some View {
    VStack(alignment: .leading, spacing: 16) {
      wifiIdentityPermission
      Button(L10n.text("Scan nearby Wi-Fi")) { model.scanNearby() }.disabled(model.busy != nil)
      Text(
        L10n.text(
          "Scan is explicit and controlled by macOS. Stop suppresses results after the OS scan returns; it cannot interrupt CoreWLAN. Identity may require location permission. Results stay in this window only."
        )
      ).font(.caption).fixedSize(horizontal: false, vertical: true)
      HStack {
        TextField(L10n.text("Filter SSID, BSSID or channel"), text: $query).textFieldStyle(
          .roundedBorder
        ).focused($searchFocused)
        Button(L10n.text("Clear search")) {
          query = ""
          searchFocused = true
        }.disabled(query.isEmpty)
      }
      if let scan = model.scan {
        Text(scan.observedAt, style: .time).font(.caption)
        let channels = Dictionary(
          grouping: scan.networks.filter { $0.channel != nil && $0.band != nil },
          by: { ($0.band ?? "Unknown") + " • " + String($0.channel ?? 0) })
        VStack(alignment: .leading, spacing: 8) {
          Text(L10n.text("Observed networks by channel")).font(.headline)
          ForEach(channels.keys.sorted(), id: \.self) { channel in
            let count = channels[channel]?.count ?? 0
            HStack {
              Text(channel).monospacedDigit().frame(width: 130, alignment: .leading)
              ProgressView(
                value: Double(count), total: Double(max(1, channels.values.map(\.count).max() ?? 1))
              )
              .accessibilityLabel(channel + ": " + String(count))
              Text(count.formatted(.number.locale(viewLocale))).monospacedDigit()
            }
          }
        }.orvenSurface()
        let filtered = scan.networks.filter {
          query.isEmpty || ($0.ssid ?? "").localizedCaseInsensitiveContains(query)
            || ($0.bssid ?? "").localizedCaseInsensitiveContains(query)
            || ($0.channel.map(String.init) ?? "").contains(query)
        }
        Text(
          String(
            format: L10n.text("%d visible networks; %d omitted."), filtered.count, scan.omitted))
        if filtered.isEmpty { Text(L10n.text("No matching Wi-Fi network was observed.")) }
        ForEach(filtered) { network in
          VStack(alignment: .leading, spacing: 6) {
            Text(network.ssid ?? L10n.text("Hidden or permission restricted")).font(.headline)
            Text(L10n.text("Security") + ": " + L10n.text(network.security)).font(.callout)
            if ["Open", "WEP", "WPA", "WPA/WPA2"].contains(network.security) {
              Text(
                L10n.text(
                  "Weak or unencrypted network. Configure your router for WPA3 or WPA2-AES; avoid WEP and legacy WPA."
                )
              )
              .font(.caption).foregroundStyle(.orange)
            }
            row("BSSID", network.bssid ?? L10n.text("Unavailable or permission restricted"))
            row(
              "Channel / band",
              integer(network.channel, unit: "") + " / " + L10n.text(network.band ?? "Unknown"))
            row(
              "RSSI / noise",
              integer(network.rssi, unit: "dBm") + " / " + integer(network.noise, unit: "dBm"))
            let same = scan.networks.filter {
              $0.channel != nil && $0.channel == network.channel && $0.band == network.band
            }.count
            row("Observed networks on this channel", String(same))
            if let rssi = network.rssi, rssi <= -75 {
              Text(
                L10n.text(
                  "Weak signal: move closer to the access point before retrying authentication or connection tests."
                )
              )
              .font(.caption).foregroundStyle(.orange)
            }
            if network.band == "2.4 GHz", let channel = network.channel {
              let overlapping = scan.networks.filter {
                $0.id != network.id && $0.band == network.band
                  && $0.channel.map { abs($0 - channel) < 5 } == true
              }.count
              Text(L10n.text("Potentially overlapping 2.4 GHz networks") + ": \(overlapping)").font(
                .caption)
            }
            if let rssi = network.rssi {
              ProgressView(value: Double(max(0, min(100, rssi + 100))), total: 100)
                .accessibilityLabel(L10n.text("RSSI") + " \(rssi) dBm")
            }
          }.orvenSurface()
        }
      }
      Text(
        L10n.text(
          "Channel counts describe this scan, not airtime utilization or interference. Different bands can reuse channel numbers; wider channels can overlap. Signal bars are a relative RSSI display."
        )
      ).font(.caption).fixedSize(horizontal: false, vertical: true)
    }
  }
  private var timeline: some View {
    VStack(alignment: .leading, spacing: 16) {
      Toggle(L10n.text("Track network changes in this window"), isOn: $model.tracksChanges)
      Button(L10n.text("Clear network changes")) { model.clearChanges() }
      Text(
        L10n.text(
          "Path events are observed while this page is open. IP, gateway, DNS and Wi-Fi identity changes compare explicit successful refreshes within ten minutes. Missing identities and adapter disappearance are not inferred as changes. First refresh establishes a baseline. No history is written to disk."
        )
      ).font(.caption).fixedSize(horizontal: false, vertical: true)
      Text(
        String(
          format: L10n.text("%d status changes and %d path events; %d older events omitted."),
          model.changes.events.count, model.pathEvents.count,
          model.changes.omitted + model.omittedPathEvents))
      if model.changes.events.isEmpty && model.pathEvents.isEmpty {
        Text(L10n.text("No network changes observed in this session."))
      }
      ForEach(model.pathEvents.reversed()) { event in
        VStack(alignment: .leading) {
          Text(L10n.text(event.state)).font(.headline)
          Text(event.interfaces).textSelection(.enabled)
          Text(event.observedAt, style: .time).font(.caption)
        }.orvenSurface()
      }
      ForEach(model.changes.events.reversed()) { event in
        VStack(alignment: .leading, spacing: 6) {
          Text(localizedField(event.field)).font(.headline)
          row("Before", L10n.text(event.before))
          row("After", L10n.text(event.after))
          Text(event.observedAt, style: .time).font(.caption)
        }.orvenSurface()
      }
    }
  }
  private func localizedField(_ field: String) -> String {
    let parts = field.components(separatedBy: " • ")
    return parts.count == 2 ? parts[0] + " • " + L10n.text(parts[1]) : L10n.text(field)
  }
  private func row(_ title: String, _ value: String) -> some View {
    HStack(alignment: .top, spacing: 16) {
      Text(L10n.text(title)).foregroundStyle(.secondary).frame(width: 180, alignment: .leading)
      Text(value).monospacedDigit().textSelection(.enabled).frame(
        maxWidth: .infinity, alignment: .leading)
    }.fixedSize(horizontal: false, vertical: true)
  }
  private func number(_ value: UInt64?) -> String {
    value.map { $0.formatted(.number.locale(viewLocale)) } ?? L10n.text("Unavailable")
  }
  private func integer(_ value: Int?, unit: String) -> String {
    value.map { $0.formatted(.number.locale(viewLocale)) + (unit.isEmpty ? "" : " " + unit) }
      ?? L10n.text("Unavailable")
  }
  private func decimal(_ value: Double?, unit: String) -> String {
    value.map {
      $0.formatted(.number.locale(viewLocale).precision(.fractionLength(1))) + " " + unit
    }
      ?? L10n.text("Unavailable")
  }
}
