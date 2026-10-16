import AppKit
import ApplicationServices
import Foundation
import MacinityCore
import MacinityMonitoring

struct WorkspaceApplication: Codable, Sendable, Identifiable {
  var id: String { bundleID }
  let bundleID: String
  let path: String
  let name: String
}
struct WorkspaceWindow: Codable, Sendable, Identifiable {
  let id: UUID
  let bundleID: String
  let title: String
  let screenID: UInt32
  let x: Double
  let y: Double
  let width: Double
  let height: Double
}
struct WorkspacePreset: Codable, Sendable, Identifiable {
  let id: UUID
  let name: String
  let applications: [WorkspaceApplication]
  let folders: [String]
  let windows: [WorkspaceWindow]
  let capturedAt: Date
  var options: WorkProfileOptions? = nil
}

struct WorkProfileOptions: Codable, Sendable, Equatable {
  var restoreWindows = true
  var awakeMinutes: Int? = nil
  var audioOutput: WorkAudioSelection? = nil
  var audioInput: WorkAudioSelection? = nil
  var valid: Bool { awakeMinutes == nil || [15, 30, 60].contains(awakeMinutes!) }
}
struct WorkAudioSelection: Codable, Sendable, Equatable {
  let uid: String
  let name: String
}
struct WorkProfileStep: Identifiable {
  enum Outcome: String { case succeeded, failed, skipped }
  let id = UUID()
  let name: String
  let detail: String
  let outcome: Outcome
}
struct WorkProfileRun: Identifiable {
  let id = UUID()
  let name: String
  let date: Date
  let steps: [WorkProfileStep]
}

@MainActor
final class WorkspacePresets: ObservableObject {
  @Published private(set) var presets: [WorkspacePreset] = []
  @Published var status = ""
  @Published private(set) var busy = false
  @Published private(set) var steps: [WorkProfileStep] = []
  @Published private(set) var runs: [WorkProfileRun] = []
  @Published var inspectedRunID: UUID?
  @Published private(set) var runningName: String?
  @Published private(set) var cancelling = false
  private let file: URL
  private var readable = true
  init(directory: URL = AppMetadata.applicationSupportDirectory()) {
    file = directory.appendingPathComponent("workspace-presets-v1.json")
    guard FileManager.default.fileExists(atPath: file.path) else { return }
    do {
      let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
      guard (attributes[.size] as? NSNumber)?.intValue ?? Int.max <= 1_048_576 else {
        throw CocoaError(.fileReadTooLarge)
      }
      presets = try JSONDecoder().decode([WorkspacePreset].self, from: Data(contentsOf: file))
      guard presets.count <= 20 else { throw CocoaError(.fileReadTooLarge) }
    } catch {
      readable = false
      status = "Workspace file could not be read; existing data is preserved"
    }
  }
  var running: [WorkspaceApplication] {
    NSWorkspace.shared.runningApplications.filter {
      $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier
    }.compactMap {
      guard let id = $0.bundleIdentifier, let url = $0.bundleURL else { return nil }
      return WorkspaceApplication(bundleID: id, path: url.path, name: $0.localizedName ?? id)
    }.sorted { $0.name < $1.name }
  }
  func save(
    name: String, selected: Set<String>, folders: [URL], options: WorkProfileOptions = .init()
  ) async {
    guard !busy else { return }
    busy = true
    defer { busy = false }
    guard readable, options.valid, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      presets.count < 20
    else {
      status = "Choose a name; at most 20 presets are retained"
      return
    }
    let applications = running.filter { selected.contains($0.id) }
    guard
      !applications.isEmpty || !folders.isEmpty || options.awakeMinutes != nil
        || options.audioOutput != nil || options.audioInput != nil
    else {
      status = "Select applications or folders first"
      return
    }
    var windows: [WorkspaceWindow] = []
    if options.restoreWindows && AXIsProcessTrusted() {
      for app in applications.prefix(20) {
        guard
          let running = NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleID)
            .first
        else { continue }
        let pid = running.processIdentifier
        let identity = try? SystemProcessAccess().metadata(pid: pid).identity
        let displays = screens
        let captured = await Task.detached(priority: .utility) {
          var captured: [WorkspaceWindow] = []
          guard let identity, (try? SystemProcessAccess().metadata(pid: pid).identity) == identity
          else { return captured }
          for window in Self.elements(pid: pid).prefix(20) {
            guard let title = Self.attribute(window, kAXTitleAttribute) as? String, !title.isEmpty,
              let position = Self.point(window), let size = Self.size(window), size.width > 0,
              size.height > 0,
              let screen = displays.first(where: { $0.bounds.contains(position) }) ?? displays.first
            else { continue }
            captured.append(
              .init(
                id: UUID(), bundleID: app.bundleID, title: String(title.prefix(500)),
                screenID: screen.id,
                x: Double((position.x - screen.bounds.minX) / screen.bounds.width),
                y: Double((position.y - screen.bounds.minY) / screen.bounds.height),
                width: Double(size.width / screen.bounds.width),
                height: Double(size.height / screen.bounds.height)))
          }
          guard (try? SystemProcessAccess().metadata(pid: pid).identity) == identity else {
            return []
          }
          return captured
        }.value
        windows.append(contentsOf: captured)
      }
    }
    let preset = WorkspacePreset(
      id: UUID(), name: String(name.prefix(80)), applications: Array(applications.prefix(20)),
      folders: Array(folders.prefix(20)).map(\.path), windows: windows, capturedAt: Date(),
      options: options)
    do {
      let updated = presets + [preset]
      try persist(updated)
      presets = updated
      status =
        !options.restoreWindows || applications.isEmpty || AXIsProcessTrusted()
        ? "Workspace saved" : "Apps and folders saved; window layout requires Accessibility access"
    } catch { status = "Workspace could not be saved" }
  }
  func restore(_ preset: WorkspacePreset) async {
    guard !busy else { return }
    guard (preset.options ?? .init()).valid else {
      status = "Invalid work profile options"
      return
    }
    busy = true
    cancelling = false
    runningName = preset.name
    steps = []
    defer {
      busy = false
      runningName = nil
      runs.insert(.init(name: preset.name, date: Date(), steps: steps), at: 0)
      runs = Array(runs.prefix(20))
      inspectedRunID = runs.first?.id
      status =
        cancelling
        ? "Work profile stopped; completed steps remain applied"
        : steps.contains { $0.outcome == .failed || $0.outcome == .skipped }
          ? "Workspace partially restored" : "Workspace restored"
    }
    let options = preset.options ?? .init()
    for app in preset.applications.prefix(20) {
      guard !cancelling else { return }
      let url = URL(fileURLWithPath: app.path)
      guard Bundle(url: url)?.bundleIdentifier == app.bundleID else {
        record(app.name, "Application changed or missing", .failed)
        continue
      }
      let config = NSWorkspace.OpenConfiguration()
      config.activates = false
      do {
        _ = try await NSWorkspace.shared.openApplication(at: url, configuration: config)
        record(app.name, "Application open request completed", .succeeded)
      } catch {
        record(app.name, error.localizedDescription, .failed)
      }
    }
    for folder in preset.folders.prefix(20) {
      guard !cancelling else { return }
      var directory: ObjCBool = false
      if FileManager.default.fileExists(atPath: folder, isDirectory: &directory),
        directory.boolValue
      {
        let opened = NSWorkspace.shared.open(URL(fileURLWithPath: folder))
        record(
          folder, opened ? "Folder open request accepted" : "Folder open request failed",
          opened ? .succeeded : .failed)
      } else {
        record(folder, "Unavailable", .failed)
      }
    }
    if options.restoreWindows && !preset.windows.isEmpty && !AXIsProcessTrusted() {
      record("Window layout", "Accessibility access required for window layouts", .skipped)
    }
    if options.restoreWindows && !preset.windows.isEmpty && AXIsProcessTrusted() {
      try? await Task.sleep(for: .milliseconds(700))
      for saved in preset.windows.prefix(400) {
        guard !cancelling else { return }
        guard [saved.x, saved.y, saved.width, saved.height].allSatisfy(\.isFinite), saved.width > 0,
          saved.height > 0,
          let app = NSRunningApplication.runningApplications(withBundleIdentifier: saved.bundleID)
            .first,
          let screen = screens.first(where: { $0.id == saved.screenID }) ?? screens.first
        else {
          record(saved.title, "Window unavailable", .skipped)
          continue
        }
        let pid = app.processIdentifier
        let identity = try? SystemProcessAccess().metadata(pid: pid).identity
        let frame = Self.frame(saved, bounds: screen.bounds)
        let restored = await Task.detached(priority: .utility) {
          guard let identity, (try? SystemProcessAccess().metadata(pid: pid).identity) == identity
          else { return false }
          let matches = Self.elements(pid: pid).filter {
            Self.attribute($0, kAXTitleAttribute) as? String == saved.title
          }
          guard matches.count == 1 else { return false }
          var position = frame.origin
          var size = frame.size
          guard let p = AXValueCreate(.cgPoint, &position),
            let value = AXValueCreate(.cgSize, &size),
            (try? SystemProcessAccess().metadata(pid: pid).identity) == identity
          else { return false }
          let resized = AXUIElementSetAttributeValue(
            matches[0], kAXSizeAttribute as CFString, value)
          let moved = AXUIElementSetAttributeValue(matches[0], kAXPositionAttribute as CFString, p)
          guard resized == .success, moved == .success, let actualPosition = Self.point(matches[0]),
            let actualSize = Self.size(matches[0])
          else { return false }
          return abs(actualPosition.x - position.x) < 3 && abs(actualPosition.y - position.y) < 3
            && abs(actualSize.width - size.width) < 3 && abs(actualSize.height - size.height) < 3
        }.value
        record(
          saved.title,
          restored ? "Window geometry verified" : "Window missing, ambiguous or layout not applied",
          restored ? .succeeded : .failed)
      }
    }
    for (role, selection) in [
      (WorkAudioRole.output, options.audioOutput), (.input, options.audioInput),
    ] {
      guard !cancelling else { return }
      if let selection {
        do {
          try await Task.detached(priority: .utility) {
            try WorkProfileAudio.setDefault(uid: selection.uid, role: role)
          }.value
          record(
            selection.name,
            role == .input ? "Default microphone verified" : "Default output verified", .succeeded)
        } catch { record(selection.name, error.localizedDescription, .failed) }
      }
    }
    guard !cancelling else { return }
    if let minutes = options.awakeMinutes {
      KeepAwakeController.shared.start(minutes: minutes, pid: nil)
      record(
        "Keep Awake", KeepAwakeController.shared.status,
        KeepAwakeController.shared.remaining > 0 ? .succeeded : .failed)
    }
    if steps.isEmpty { record("Work Profiles", "No applicable steps", .skipped) }
  }
  func cancelRun() { if busy { cancelling = true } }
  private func record(_ name: String, _ detail: String, _ outcome: WorkProfileStep.Outcome) {
    steps.append(.init(name: name, detail: detail, outcome: outcome))
  }
  static func frame(_ window: WorkspaceWindow, bounds: CGRect) -> CGRect {
    let width = min(bounds.width, max(200, window.width * bounds.width))
    let height = min(bounds.height, max(150, window.height * bounds.height))
    return CGRect(
      x: min(bounds.maxX - width, max(bounds.minX, bounds.minX + window.x * bounds.width)),
      y: min(bounds.maxY - height, max(bounds.minY, bounds.minY + window.y * bounds.height)),
      width: width, height: height)
  }
  func remove(_ preset: WorkspacePreset) {
    guard readable, !busy else { return }
    do {
      // Keep a recoverable copy before removing a saved preset.
      let backup = file.deletingLastPathComponent().appendingPathComponent(
        "workspace-presets-backup-\(UUID().uuidString).json")
      try JSONEncoder().encode(presets).write(to: backup, options: .atomic)
      let updated = presets.filter { $0.id != preset.id }
      try persist(updated)
      presets = updated
      status = "Preset removed; recovery copy retained"
    } catch { status = "Workspace could not be saved" }
  }
  private func persist(_ value: [WorkspacePreset]) throws {
    let data = try JSONEncoder().encode(value)
    guard data.count <= 1_048_576 else { throw CocoaError(.fileWriteOutOfSpace) }
    try FileManager.default.createDirectory(
      at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: file, options: .atomic)
  }
  private var screens: [(id: UInt32, bounds: CGRect)] {
    NSScreen.screens.compactMap {
      guard
        let id = ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?
          .uint32Value
      else { return nil }
      return (id, CGDisplayBounds(id))
    }
  }
  nonisolated private static func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success
      ? value : nil
  }
  nonisolated private static func elements(pid: pid_t) -> [AXUIElement] {
    let app = AXUIElementCreateApplication(pid)
    AXUIElementSetMessagingTimeout(app, 0.2)
    return attribute(app, kAXWindowsAttribute) as? [AXUIElement] ?? []
  }
  nonisolated private static func point(_ element: AXUIElement) -> CGPoint? {
    guard let value = attribute(element, kAXPositionAttribute),
      CFGetTypeID(value) == AXValueGetTypeID()
    else { return nil }
    var point = CGPoint.zero
    return AXValueGetValue(value as! AXValue, .cgPoint, &point) ? point : nil
  }
  nonisolated private static func size(_ element: AXUIElement) -> CGSize? {
    guard let value = attribute(element, kAXSizeAttribute), CFGetTypeID(value) == AXValueGetTypeID()
    else { return nil }
    var size = CGSize.zero
    return AXValueGetValue(value as! AXValue, .cgSize, &size) ? size : nil
  }
}
