import AppKit
import MacinityCore
import MacinityMonitoring
import SwiftUI

struct ExternalDrivesView: View {
  @State private var drives: [ExternalDrive] = []
  @State private var busy = false
  @State private var request = 0
  @State private var status = ""
  @State private var locks = ""
  @State private var pending: ExternalDrive?
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        MacinityPageHeader(title: L10n.text("External Drives & File Locks"))
        HStack {
          Button(L10n.text("Refresh")) { request += 1 }.disabled(busy)
          if busy { ProgressView().controlSize(.small) }
        }
        Text(
          L10n.text(
            "External disks and their partitions, including unmounted entries. Eject uses macOS without force. Open-file inspection may omit restricted processes; it does not prove a file is locked."
          )
        )
        .font(.caption).foregroundStyle(.secondary)
        if !status.isEmpty { Text(status).foregroundStyle(.orange) }
        if drives.isEmpty && !busy { Text(L10n.text("No external disks in this observation")) }
        ForEach(drives) { drive in
          VStack(alignment: .leading, spacing: 10) {
            Text(drive.name + " · " + drive.id).font(.headline)
            Text(drive.format + " · " + drive.protocolName).font(.caption)
            Text(drive.mount ?? L10n.text("Not mounted")).textSelection(.enabled)
            Text(
              L10n.text("Capacity") + ": " + bytes(drive.capacity) + " · " + L10n.text("Free")
                + ": " + bytes(drive.free))
            HStack {
              if let mount = drive.mount {
                Button(L10n.text("Show in Finder")) {
                  NSWorkspace.shared.open(URL(fileURLWithPath: mount))
                }
                Button(L10n.text("Inspect open files")) { Task { await inspect(drive) } }.disabled(
                  busy || !mount.hasPrefix("/Volumes/"))
              }
              if drive.canEject {
                Button(L10n.text("Review eject")) { pending = drive }.disabled(busy)
              }
            }
          }.macinitySurface()
        }
        if !locks.isEmpty {
          Text(L10n.text("Observed open files")).font(.headline)
          Text(locks).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
          Button(L10n.text("Clear")) { locks = "" }
        }
      }.padding(28)
    }.task(id: request) { await refresh() }
      .sheet(item: $pending) { drive in
        VStack(alignment: .leading, spacing: 16) {
          Text(L10n.text("Eject external drive?")).font(.title2.bold())
          Text(drive.name + "\n" + (drive.mount ?? ""))
          Text(
            L10n.text(
              "Finish file operations first. macOS may eject related volumes on the same device. Busy devices will not be forcibly unmounted."
            ))
          HStack {
            Button(L10n.text("Cancel")) { pending = nil }
            Button(L10n.text("Eject")) {
              pending = nil
              Task { await eject(drive) }
            }
          }
        }.padding(24).frame(width: 460)
      }
  }
  private func bytes(_ value: Int64?) -> String {
    value.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) }
      ?? L10n.text("Unavailable")
  }
  private func refresh() async {
    busy = true
    let worker = Task.detached { try ExternalDriveInspection.read() }
    do {
      let value = try await withTaskCancellationHandler(
        operation: { try await worker.value }, onCancel: { worker.cancel() })
      if !Task.isCancelled {
        drives = value
        status = ""
      }
    } catch {
      if !Task.isCancelled {
        status = L10n.text("Drive inspection failed; results may be incomplete")
      }
    }
    busy = false
  }
  private func inspect(_ drive: ExternalDrive) async {
    guard let mount = drive.mount else { return }
    busy = true
    locks = ""
    do {
      let output = try await Task.detached {
        let fresh = try ExternalDriveInspection.info(drive.id)
        guard fresh.mount == mount, fresh.uuid == drive.uuid else {
          throw CocoaError(.fileReadUnknown)
        }
        return try UtilityCommand.fileLocks(mount).read()
      }.value
      locks =
        output.text.isEmpty
        ? L10n.text("No readable open files; restricted processes may be missing")
        : String(output.text.prefix(24000))
      status = output.status > 1 ? L10n.text("Inspection failed or access is restricted") : ""
    } catch { status = L10n.text("Inspection failed or access is restricted") }
    busy = false
  }
  private func eject(_ drive: ExternalDrive) async {
    busy = true
    do {
      let fresh = try await Task.detached { try ExternalDriveInspection.info(drive.id) }.value
      guard fresh.canEject, fresh.uuid == drive.uuid, fresh.mount == drive.mount,
        let mount = fresh.mount
      else { throw CocoaError(.fileReadUnknown) }
      try NSWorkspace.shared.unmountAndEjectDevice(at: URL(fileURLWithPath: mount))
      status = L10n.text("Eject request completed")
      await refresh()
    } catch {
      status = L10n.text(
        "Eject failed or device changed. Inspect open files; no force eject was attempted.")
    }
    busy = false
  }
}
