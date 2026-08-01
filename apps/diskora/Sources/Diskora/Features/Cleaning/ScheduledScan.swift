import AppKit
import Darwin
import Foundation
import UserNotifications

struct ScheduledScanService: Sendable {
  static let label = "com.thang.diskora.scheduled-scan"

  private var launchAgentURL: URL {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/LaunchAgents/\(Self.label).plist")
  }

  func install(intervalHours: Int) async throws {
    guard (1...168).contains(intervalHours) else {
      throw CocoaError(.validationMissingMandatoryProperty)
    }
    let appURL = Bundle.main.bundleURL
    guard appURL.pathExtension == "app" else {
      throw NSError(
        domain: Self.label, code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Chỉ có thể lập lịch từ bản Diskora.app đã đóng gói."]
      )
    }
    let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [
      .alert, .sound,
    ])
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
    reloadLaunchAgent()
    UserDefaults.standard.set(intervalHours, forKey: "scheduledScanIntervalHours")
  }

  func uninstall() throws {
    bootoutLaunchAgent()
    if FileManager.default.fileExists(atPath: launchAgentURL.path) {
      try FileManager.default.removeItem(at: launchAgentURL)
    }
    UserDefaults.standard.removeObject(forKey: "scheduledScanIntervalHours")
  }

  func runNow() async {
    let targets = CleaningTarget.defaults.filter { $0.confidence == .safe }
    let results = await CleanerService().scan(targets: targets)
    let bytes = results.reduce(Int64(0)) { $0 + $1.bytes }
    let issues = results.compactMap(\.issue).count
    let content = UNMutableNotificationContent()
    content.title = "Diskora đã quét xong"
    content.body =
      issues == 0
      ? "Có \(ByteCount.string(bytes)) dữ liệu an toàn để bạn xem xét. Diskora chưa xóa gì."
      : "Có \(ByteCount.string(bytes)) để xem xét và \(issues) vị trí không thể đọc. Diskora chưa xóa gì."
    content.sound = .default
    try? await UNUserNotificationCenter.current().add(
      UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    UserDefaults.standard.set(Date(), forKey: "scheduledScanLastRun")
    UserDefaults.standard.set(bytes, forKey: "scheduledScanLastBytes")
  }

  private func reloadLaunchAgent() {
    bootoutLaunchAgent()
    runLaunchctl(["bootstrap", "gui/\(getuid())", launchAgentURL.path])
  }

  private func bootoutLaunchAgent() {
    runLaunchctl(["bootout", "gui/\(getuid())/\(Self.label)"])
  }

  private func runLaunchctl(_ arguments: [String]) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    process.arguments = arguments
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    try? process.run()
    process.waitUntilExit()
  }
}

@MainActor
final class ScheduledScanViewModel: ObservableObject {
  @Published var intervalHours = UserDefaults.standard.integer(forKey: "scheduledScanIntervalHours")
  @Published var isWorking = false
  @Published var status = "Lịch quét chỉ thông báo; Diskora không tự xóa dữ liệu."
  @Published var errorMessage: String?
  private let service = ScheduledScanService()

  var isEnabled: Bool { intervalHours > 0 }
  var lastRun: Date? { UserDefaults.standard.object(forKey: "scheduledScanLastRun") as? Date }
  var lastBytes: Int64 { Int64(UserDefaults.standard.integer(forKey: "scheduledScanLastBytes")) }

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
