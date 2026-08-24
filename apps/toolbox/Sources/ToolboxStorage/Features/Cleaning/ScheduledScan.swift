import AppKit
import Darwin
import Foundation
import ToolboxCore
import UserNotifications

protocol LaunchctlRunning: Sendable {
  func run(_ arguments: [String]) throws
}

protocol NotificationAuthorizing: Sendable {
  func requestAuthorization() async throws -> Bool
}

struct SystemNotificationAuthorizer: NotificationAuthorizing {
  func requestAuthorization() async throws -> Bool {
    try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
  }
}

struct SystemLaunchctlRunner: LaunchctlRunning {
  func run(_ arguments: [String]) throws {
    let process = Process()
    let errorPipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    process.arguments = arguments
    process.standardOutput = FileHandle.nullDevice
    process.standardError = errorPipe
    try process.run()
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      let detail = String(decoding: errorData, as: UTF8.self)
        .trimmingCharacters(in: .whitespacesAndNewlines)
      throw NSError(
        domain: ScheduledScanService.label, code: Int(process.terminationStatus),
        userInfo: [
          NSLocalizedDescriptionKey: detail.isEmpty
            ? "launchctl failed with status \(process.terminationStatus)" : detail
        ])
    }
  }
}

public struct ScheduledScanService: Sendable {
  public static let label = "com.thang.toolbox.scheduled-scan"
  public static let legacyLabel = "com.thang.diskora.scheduled-scan"
  private let homeURL: URL
  private let bundleURL: URL
  private let launchctl: any LaunchctlRunning
  private let notifications: any NotificationAuthorizing

  private var launchAgentURL: URL {
    homeURL
      .appendingPathComponent("Library/LaunchAgents/\(Self.label).plist")
  }

  public var legacyLaunchAgentURL: URL {
    homeURL.appendingPathComponent("Library/LaunchAgents/\(Self.legacyLabel).plist")
  }

  public var hasLegacyLaunchAgent: Bool {
    FileManager.default.fileExists(atPath: legacyLaunchAgentURL.path)
  }

  public init(
    homeURL: URL = FileManager.default.homeDirectoryForCurrentUser,
    bundleURL: URL = Bundle.main.bundleURL
  ) {
    self.homeURL = homeURL.standardizedFileURL
    self.bundleURL = bundleURL.standardizedFileURL
    launchctl = SystemLaunchctlRunner()
    notifications = SystemNotificationAuthorizer()
  }

  init(
    homeURL: URL, bundleURL: URL, launchctl: any LaunchctlRunning,
    notifications: any NotificationAuthorizing
  ) {
    self.homeURL = homeURL.standardizedFileURL
    self.bundleURL = bundleURL.standardizedFileURL
    self.launchctl = launchctl
    self.notifications = notifications
  }

  public func install(intervalHours: Int) async throws {
    guard (1...168).contains(intervalHours) else {
      throw CocoaError(.validationMissingMandatoryProperty)
    }
    let appURL = bundleURL
    guard appURL.pathExtension == "app" else {
      throw NSError(
        domain: Self.label, code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Chỉ có thể lập lịch từ bản Toolbox.app đã đóng gói."]
      )
    }
    let granted = try await notifications.requestAuthorization()
    guard granted else {
      throw NSError(
        domain: Self.label, code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Cần cho phép Notification để bật lịch quét."])
    }
    let payload: [String: Any] = [
      "Label": Self.label,
      "ProgramArguments": [
        "/usr/bin/open", "-gj", appURL.path, "--args", "--scheduled-scan",
      ],
      "StartInterval": intervalHours * 3_600,
      "ProcessType": "Background",
    ]
    let data = try PropertyListSerialization.data(
      fromPropertyList: payload, format: .xml, options: 0)
    try FileManager.default.createDirectory(
      at: launchAgentURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: launchAgentURL, options: .atomic)
    do {
      try reloadLaunchAgent()
    } catch {
      try? FileManager.default.removeItem(at: launchAgentURL)
      throw error
    }
    UserDefaults.standard.set(intervalHours, forKey: "toolbox.scheduledScanIntervalHours")
  }

  public func uninstall() throws {
    try? bootoutLaunchAgent(label: Self.label)
    if FileManager.default.fileExists(atPath: launchAgentURL.path) {
      try FileManager.default.removeItem(at: launchAgentURL)
    }
    UserDefaults.standard.removeObject(forKey: "toolbox.scheduledScanIntervalHours")
  }

  public func replaceLegacyLaunchAgent(intervalHours: Int) async throws {
    guard hasLegacyLaunchAgent else { return }
    try await install(intervalHours: intervalHours)
    try? bootoutLaunchAgent(label: Self.legacyLabel)
    try FileManager.default.removeItem(at: legacyLaunchAgentURL)
  }

  public func runNow() async {
    ScanActivityRegistry.shared.begin()
    defer { ScanActivityRegistry.shared.end() }
    let targets = CleaningTarget.defaults.filter { $0.confidence == .safe }
    let results = await CleanerService().scan(targets: targets)
    let bytes = results.reduce(Int64(0)) { $0 + $1.bytes }
    let issues = results.compactMap(\.issue).count
    let content = UNMutableNotificationContent()
    content.title = "Toolbox đã quét xong"
    content.body =
      issues == 0
      ? "Có \(ByteCount.string(bytes)) dữ liệu an toàn để bạn xem xét. Toolbox chưa xóa gì."
      : "Có \(ByteCount.string(bytes)) để xem xét và \(issues) vị trí không thể đọc. Toolbox chưa xóa gì."
    content.sound = .default
    try? await UNUserNotificationCenter.current().add(
      UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    UserDefaults.standard.set(Date(), forKey: "toolbox.scheduledScanLastRun")
    UserDefaults.standard.set(bytes, forKey: "toolbox.scheduledScanLastBytes")
  }

  private func reloadLaunchAgent() throws {
    try? bootoutLaunchAgent(label: Self.label)
    try launchctl.run(["bootstrap", "gui/\(getuid())", launchAgentURL.path])
  }

  private func bootoutLaunchAgent(label: String) throws {
    try launchctl.run(["bootout", "gui/\(getuid())/\(label)"])
  }
}

@MainActor
final class ScheduledScanViewModel: ObservableObject {
  @Published var intervalHours = UserDefaults.standard.integer(
    forKey: "toolbox.scheduledScanIntervalHours")
  @Published var isWorking = false
  @Published var status = "Lịch quét chỉ thông báo; Toolbox không tự xóa dữ liệu."
  @Published var errorMessage: String?
  private let service = ScheduledScanService()

  var isEnabled: Bool { intervalHours > 0 }
  var lastRun: Date? {
    UserDefaults.standard.object(forKey: "toolbox.scheduledScanLastRun") as? Date
  }
  var lastBytes: Int64 {
    Int64(UserDefaults.standard.integer(forKey: "toolbox.scheduledScanLastBytes"))
  }

  func enable(hours: Int) {
    guard !isWorking else { return }
    isWorking = true
    Task {
      do {
        try await service.install(intervalHours: hours)
        intervalHours = hours
        status = "Đã bật lịch quét mỗi \(hours) giờ."
      } catch {
        errorMessage = error.localizedDescription
      }
      isWorking = false
    }
  }

  func disable() {
    do {
      try service.uninstall()
      intervalHours = 0
      status = "Đã tắt lịch quét."
    } catch { errorMessage = error.localizedDescription }
  }
}
