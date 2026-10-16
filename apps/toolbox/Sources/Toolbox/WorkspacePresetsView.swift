import AppKit
import ApplicationServices
import SwiftUI
import ToolboxCore

struct WorkspacePresetsView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @ObservedObject private var model = ToolboxRuntime.shared.workspaces
  @State private var selected: Set<String> = []
  @State private var folders: [URL] = []
  @State private var name = "Code"
  @State private var options = WorkProfileOptions()
  @State private var outputs: [WorkAudioDevice] = []
  @State private var inputs: [WorkAudioDevice] = []
  @State private var audioStatus = ""
  @State private var audioRequest = 0
  @State private var pending: WorkspacePreset?
  var body: some View {
    let _ = languageCode
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        OrvenPageHeader(title: L10n.text("Work Profiles"))
        Text(
          L10n.text(
            "Group apps, folders, window layout, audio devices and timed Keep Awake. Apply only after reviewing every step. No automatic triggers or automatic rollback."
          )
        )
        .font(.callout).foregroundStyle(OrvenTheme.secondary)
        if model.busy {
          HStack {
            ProgressView().controlSize(.small)
            Text(model.runningName ?? L10n.text("Saving workspace"))
            if model.runningName != nil {
              Button(L10n.text("Stop after current step")) { model.cancelRun() }.disabled(
                model.cancelling)
            }
          }.orvenSurface()
        }
        VStack(alignment: .leading, spacing: 14) {
          Text(L10n.text("Create work profile")).font(.title2.bold())
          TextField(L10n.text("Preset name"), text: $name).textFieldStyle(.roundedBorder)
          HStack {
            ForEach(["Code", "Data", "Meeting", "Travel"], id: \.self) { title in
              Button(L10n.text(title)) { name = title }
            }
          }
          Text(L10n.text("Select running applications")).font(.headline)
          LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 200), alignment: .leading)], alignment: .leading
          ) {
            ForEach(model.running) { app in
              Toggle(
                app.name,
                isOn: Binding(
                  get: { selected.contains(app.id) },
                  set: {
                    if $0 { selected.insert(app.id) } else { selected.remove(app.id) }
                  }))
            }
          }
          HStack {
            Button(L10n.text("Add folders")) {
              let panel = NSOpenPanel()
              panel.canChooseFiles = false
              panel.canChooseDirectories = true
              panel.allowsMultipleSelection = true
              if panel.runModal() == .OK {
                folders = Array(Set(folders + panel.urls)).sorted { $0.path < $1.path }
              }
            }
            Button(L10n.text("Clear folders")) { folders = [] }
          }
          ForEach(folders, id: \.self) { Text($0.path).font(.caption).textSelection(.enabled) }
          Toggle(L10n.text("Capture and restore window layout"), isOn: $options.restoreWindows)
          Text(
            L10n.text(
              AXIsProcessTrusted()
                ? "Accessibility access available"
                : "Accessibility access required for window layouts")
          ).font(.caption)
          Button(L10n.text("Open Accessibility Settings")) {
            if let url = URL(
              string:
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            {
              NSWorkspace.shared.open(url)
            }
          }
          OrvenChoicePicker(
            L10n.text("Keep Awake duration"),
            selection: Binding(
              get: { options.awakeMinutes ?? 0 }, set: { options.awakeMinutes = $0 == 0 ? nil : $0 }
            ),
            options: [
              (0, L10n.text("Leave unchanged")), (15, "15 min"), (30, "30 min"), (60, "60 min"),
            ], minimumWidth: 120)
          Text(
            L10n.text(
              "A selected duration replaces any active Macinity Keep Awake session. Lock Screen remains unchanged."
            )
          )
          .font(.caption).foregroundStyle(OrvenTheme.secondary)
          audioChoices(role: .output, devices: outputs)
          audioChoices(role: .input, devices: inputs)
          HStack {
            Button(L10n.text("Refresh audio devices")) { audioRequest += 1 }
            Text(L10n.text(audioStatus)).font(.caption)
          }
          Text(
            L10n.text(
              "Changes the system default device only. Apps with their own audio routing may ignore it. No audio is recorded."
            )
          )
          .font(.caption).foregroundStyle(OrvenTheme.secondary)
          Button(L10n.text("Save workspace")) {
            Task {
              await model.save(name: name, selected: selected, folders: folders, options: options)
            }
          }.buttonStyle(.borderedProminent)
        }.disabled(model.busy).frame(maxWidth: .infinity, alignment: .leading).orvenSurface()
        if !model.status.isEmpty { Text(L10n.text(model.status)).font(.callout) }
        Text(L10n.text("Saved work profiles")).font(.title2.bold())
        if model.presets.isEmpty { Text(L10n.text("No saved work profiles")) }
        ForEach(model.presets) { preset in
          VStack(alignment: .leading, spacing: 10) {
            Text(preset.name).font(.headline)
            Text(preset.applications.map(\.name).joined(separator: ", ")).font(.caption)
            Text(
              "\(preset.windows.count) " + L10n.text("saved windows")
                + " · \(preset.folders.count) " + L10n.text("folders"))
            profileOptions(preset)
            HStack {
              Button(L10n.text("Review restore")) { pending = preset }
              Button(L10n.text("Remove preset")) { model.remove(preset) }
            }.disabled(model.busy)
          }.frame(maxWidth: .infinity, alignment: .leading).orvenSurface()
        }
        if !model.runs.isEmpty {
          OrvenChoicePicker(
            L10n.text("Recent profile runs"), selection: $model.inspectedRunID,
            options: model.runs.map {
              (
                Optional($0.id),
                $0.name + " · " + workflowTimestamp($0.date, language: languageCode)
              )
            }, minimumWidth: 200
          )
          .disabled(model.busy)
        }
        let displayedSteps =
          model.busy
          ? model.steps : (model.runs.first { $0.id == model.inspectedRunID }?.steps ?? model.steps)
        if !displayedSteps.isEmpty {
          Text(L10n.text("Step results")).font(.title2.bold())
          ForEach(displayedSteps) { step in
            VStack(alignment: .leading, spacing: 4) {
              Label(
                step.name,
                systemImage: step.outcome == .succeeded
                  ? "checkmark.circle"
                  : step.outcome == .failed ? "exclamationmark.triangle" : "minus.circle")
              Text(L10n.text(step.outcome.rawValue) + " · " + L10n.text(step.detail)).font(.caption)
            }.frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        Text(
          L10n.text(
            "Successful steps remain applied if another step fails or you stop. Results are kept for this app session; profiles stay on this Mac."
          )
        )
        .font(.caption).foregroundStyle(OrvenTheme.secondary)
      }.padding(28).frame(maxWidth: 1400, alignment: .leading)
    }.background(OrvenTheme.canvas)
      .task(id: audioRequest) {
        let worker = Task.detached(priority: .utility) {
          (try WorkProfileAudio.devices(.output), try WorkProfileAudio.devices(.input))
        }
        do {
          let devices = try await withTaskCancellationHandler(
            operation: { try await worker.value }, onCancel: { worker.cancel() })
          if !Task.isCancelled {
            outputs = devices.0
            inputs = devices.1
            audioStatus = "Observation completed."
          }
        } catch { if !Task.isCancelled { audioStatus = "Audio devices unavailable" } }
      }
      .sheet(item: $pending) { preset in
        VStack(alignment: .leading, spacing: 16) {
          Text(L10n.text("Restore workspace?")).font(.title2.bold())
          ScrollView {
            VStack(alignment: .leading, spacing: 12) {
              Text(preset.name).font(.headline)
              ForEach(preset.applications) { Text($0.path).font(.caption) }
              ForEach(preset.folders, id: \.self) { Text($0).font(.caption) }
              Text("\(preset.windows.count) " + L10n.text("saved windows"))
              ForEach(preset.windows) { window in
                Text(window.bundleID + " · " + window.title).font(.caption)
              }
              profileOptions(preset)
              Text(
                L10n.text(
                  "This opens listed apps and folders, applies selected window/audio settings and may replace Keep Awake. Steps are checked at execution. Existing apps are not closed; failures do not undo completed steps."
                ))
            }.frame(maxWidth: .infinity, alignment: .leading)
          }.frame(maxHeight: 340)
          HStack {
            Button(L10n.text("Cancel")) { pending = nil }.keyboardShortcut(.cancelAction)
            Button(L10n.text("Restore")) {
              pending = nil
              Task { await model.restore(preset) }
            }
            .disabled(model.busy)
          }
        }.padding(24).frame(width: 520)
      }
  }
  private func profileOptions(_ preset: WorkspacePreset) -> some View {
    let value = preset.options ?? .init()
    return VStack(alignment: .leading, spacing: 6) {
      Text(L10n.text(value.restoreWindows ? "Window layout enabled" : "Window layout unchanged"))
      Text(
        L10n.text("Keep Awake") + ": "
          + (value.awakeMinutes.map { "\($0) min" } ?? L10n.text("Leave unchanged")))
      Text(
        L10n.text("Audio output") + ": " + (value.audioOutput?.name ?? L10n.text("Leave unchanged"))
      )
      Text(
        L10n.text("Microphone") + ": " + (value.audioInput?.name ?? L10n.text("Leave unchanged")))
    }.font(.caption)
  }
  private func audioChoices(role: WorkAudioRole, devices: [WorkAudioDevice]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      OrvenChoicePicker(
        L10n.text(role == .output ? "Audio output" : "Microphone"),
        selection: Binding(
          get: { (role == .output ? options.audioOutput : options.audioInput)?.uid ?? "" },
          set: { uid in
            let selected = devices.first { $0.uid == uid }.map {
              WorkAudioSelection(uid: $0.uid, name: $0.name)
            }
            if role == .output {
              options.audioOutput = selected
            } else {
              options.audioInput = selected
            }
          }), options: [("", L10n.text("Leave unchanged"))] + devices.map { ($0.uid, $0.name) },
        minimumWidth: 180)
    }
  }
}
