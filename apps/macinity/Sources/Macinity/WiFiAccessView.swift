import AppKit
import CoreImage.CIFilterBuiltins
import MacinityCore
import MacinityMonitoring
import SwiftUI

struct WiFiAccessView: View {
  @State private var query = ""
  @State private var page = 0
  @State private var saved: [SavedWiFiNetwork] = []
  @State private var status = ""
  @State private var request = 0
  @State private var ssid = ""
  @State private var password = ""
  @State private var open = false
  @State private var hidden = false
  @State private var qr: NSImage?
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(L10n.text("Saved Wi-Fi & Sharing")).font(.title2.bold())
      Text(
        L10n.text(
          "Only profiles exposed by macOS are listed. Missing profiles or names may be restricted; this is not a complete connection history. Passwords are never read by Macinity."
        )
      )
      .font(.caption).foregroundStyle(.secondary)
      HStack {
        Button(L10n.text("Refresh saved networks")) { request += 1 }
        Button(L10n.text("Open Passwords")) { openPasswords() }
      }
      Text(L10n.text(status)).font(.caption)
      TextField(L10n.text("Filter saved networks"), text: $query).textFieldStyle(.roundedBorder)
      let filtered = saved.filter {
        query.isEmpty || ($0.name ?? "").localizedStandardContains(query)
      }
      HStack {
        Button(L10n.text("Previous")) { page = max(0, page - 1) }.disabled(page == 0)
        Text(
          "\(min(page * 10 + 1, filtered.count))–\(min((page + 1) * 10, filtered.count)) / \(filtered.count)"
        ).font(.caption)
        Button(L10n.text("Next")) { page += 1 }.disabled((page + 1) * 10 >= filtered.count)
      }
      ForEach(Array(filtered.dropFirst(page * 10).prefix(10))) { network in
        HStack {
          Text(network.name ?? L10n.text("Hidden or permission restricted"))
          Spacer()
          Text(network.interface + " · " + L10n.text(network.security)).foregroundStyle(.secondary)
        }
      }
      Divider()
      Text(L10n.text("Share your Wi-Fi with QR")).font(.headline)
      Text(
        L10n.text(
          "Enter credentials for a network you own or may share. The QR contains the password. It stays in memory and is cleared when you leave this page; no upload or automatic copy."
        )
      )
      .font(.caption).foregroundStyle(.secondary)
      TextField("SSID", text: $ssid).textFieldStyle(.roundedBorder)
      SecureField(L10n.text("Wi-Fi password"), text: $password).textFieldStyle(.roundedBorder)
        .disabled(open)
      Toggle(L10n.text("Open network (no password)"), isOn: $open)
      Toggle(L10n.text("Hidden network"), isOn: $hidden)
      HStack {
        Button(L10n.text("Generate QR")) { generate() }
        Button(L10n.text("Clear")) { clear() }
      }
      if let qr {
        Image(nsImage: qr).interpolation(.none).resizable().scaledToFit().frame(
          width: 240, height: 240
        ).accessibilityLabel(L10n.text("Wi-Fi sharing QR"))
      }
    }.macinitySurface()
      .task(id: request) {
        let worker = Task.detached(priority: .utility) { try WiFiUtilities.saved() }
        do {
          let result = try await withTaskCancellationHandler(
            operation: { try await worker.value }, onCancel: { worker.cancel() })
          if !Task.isCancelled {
            saved = result
            status = result.isEmpty ? "No readable saved networks" : "Observation completed."
          }
        } catch { if !Task.isCancelled { status = "Saved network access is unavailable" } }
      }
      .onChange(of: query) { _ in page = 0 }
      .onChange(of: saved.count) { _ in page = 0 }
      .onChange(of: ssid) { _ in qr = nil }
      .onChange(of: password) { _ in qr = nil }
      .onChange(of: open) { _ in qr = nil }
      .onChange(of: hidden) { _ in qr = nil }
      .onDisappear { clear() }
  }
  private func clear() {
    password = ""
    ssid = ""
    qr = nil
  }
  private func generate() {
    do {
      let payload = try WiFiUtilities.qrPayload(
        ssid: ssid, password: password, open: open, hidden: hidden)
      let filter = CIFilter.qrCodeGenerator()
      filter.message = Data(payload.utf8)
      guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 8, y: 8)),
        let image = CIContext().createCGImage(output, from: output.extent)
      else { return }
      qr = NSImage(
        cgImage: image, size: NSSize(width: output.extent.width, height: output.extent.height))
    } catch {
      status = "Enter a valid SSID and password"
      qr = nil
    }
  }
  private func openPasswords() {
    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Passwords") {
      NSWorkspace.shared.open(url)
    } else if let url = URL(
      string: "x-apple.systempreferences:com.apple.Passwords-Settings.extension")
    {
      NSWorkspace.shared.open(url)
    }
  }
}
