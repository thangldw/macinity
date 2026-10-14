import SwiftUI
import ToolboxCore

struct APFSSpaceInspectorView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @State private var volume = APFSStartupVolume.data
  @State private var reading: APFSSpaceInspection?
  @State private var isReading = false
  @State private var failed = false
  @State private var task: Task<Void, Never>?
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(L10n.text("Hidden Space & Snapshots")).font(.title2.bold())
        Spacer()
        if isReading { ProgressView().controlSize(.small) }
        Button(L10n.text("Inspect APFS space")) { refresh() }.disabled(isReading)
      }
      Picker(L10n.text("Startup volume"), selection: $volume) {
        Text(L10n.text("Data volume")).tag(APFSStartupVolume.data)
        Text(L10n.text("System volume")).tag(APFSStartupVolume.system)
      }.pickerStyle(.menu).disabled(isReading)
        .onChange(of: volume) { _ in
          reading = nil
          failed = false
        }
      Text(
        L10n.text(
          "Selected startup volume only. APFS container capacity is shared by volumes; folder scans, available space and snapshot sizes are different measurements."
        )
      )
      .font(.caption).foregroundStyle(.secondary)
      if failed {
        Text(L10n.text("APFS inspection failed or is unsupported. Refresh to try again."))
      }
      if let reading {
        Text(reading.observedAt, style: .time).font(.caption)
        HStack(alignment: .top, spacing: 20) {
          field("APFS container capacity", reading.containerTotal)
          field("APFS container free", reading.containerFree)
          field("Selected volume used", reading.volumeUsed)
        }
        if !reading.volumes.isEmpty {
          Text(L10n.text("Volumes sharing this container")).font(.headline)
          ForEach(reading.volumes) { volume in
            HStack {
              Text(volume.name).textSelection(.enabled)
              Text(volume.roles.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary)
              Spacer()
              Text(volume.bytes.map(ByteCount.string) ?? L10n.text("Unavailable")).monospacedDigit()
            }
          }
          if reading.omittedVolumes > 0 {
            Text(String(format: L10n.text("%d volume entries omitted."), reading.omittedVolumes))
          }
          field("Unattributed container allocation", reading.containerRemainder)
          Text(
            L10n.text(
              "Container remainder uses OS-reported capacity minus free space and listed volume usage. It is not hidden-file size or exclusive snapshot space. Incomplete or inconsistent accounting stays unknown."
            )
          )
          .font(.caption).foregroundStyle(.secondary)
        }
        Text(
          L10n.text(
            "Unaccounted space is not measured here. It may include unreadable files, other volumes, filesystem metadata, clones or snapshots; Orven does not attribute the remainder to one cause."
          ))
        Text(L10n.text("APFS snapshots")).font(.headline)
        if reading.snapshots.isEmpty {
          Text(
            L10n.text(
              "No APFS snapshots reported for the selected volume. Other volumes may have snapshots."
            ))
        }
        ForEach(reading.snapshots) { snapshot in
          VStack(alignment: .leading, spacing: 4) {
            Text(snapshot.name).font(.caption.monospaced()).textSelection(.enabled)
            Text(
              L10n.text(
                snapshot.purgeable.map {
                  $0
                    ? "OS marks this snapshot purgeable."
                    : "OS does not mark this snapshot purgeable."
                } ?? "Snapshot purgeability unavailable.")
            )
            .font(.caption).foregroundStyle(.secondary)
          }
        }
        if reading.omitted > 0 {
          Text(String(format: L10n.text("%d snapshot entries omitted."), reading.omitted))
        }
        Text(
          L10n.text(
            "Exclusive snapshot bytes are unavailable from this inspection. Snapshot count does not measure reclaimable space. No snapshots are created, mounted, thinned or deleted."
          )
        )
        .font(.caption).foregroundStyle(.secondary)
      } else if !isReading {
        Text(L10n.text("Inspect to read container space and selected-volume snapshots."))
      }
    }.orvenSurface().onDisappear { task?.cancel() }
  }
  private func field(_ title: String, _ bytes: Int64?) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(L10n.text(title)).font(.caption).foregroundStyle(.secondary)
      Text(bytes.map(ByteCount.string) ?? L10n.text("Unavailable")).font(.title3.monospacedDigit())
    }.frame(maxWidth: .infinity, alignment: .leading)
  }
  private func refresh() {
    isReading = true
    failed = false
    task = Task {
      let target = volume
      let worker = Task.detached(priority: .utility) {
        try APFSSpaceInspection.read(volume: target)
      }
      defer { isReading = false }
      do {
        let value = try await withTaskCancellationHandler {
          try await worker.value
        } onCancel: {
          worker.cancel()
        }
        try Task.checkCancellation()
        reading = value
      } catch is CancellationError {
      } catch { failed = true }
    }
  }
}
