import Foundation

enum DeveloperCleanupTool: String, CaseIterable, Sendable {
  case simulator = "Xcode Simulator"
  case docker = "Docker"
  case homebrew = "Homebrew"
  case npm = "npm"
  case pip = "pip"
}

struct DeveloperCleanupAction: Identifiable, Sendable {
  let tool: DeveloperCleanupTool
  let executable: URL
  let arguments: [String]
  let detail: String
  let estimatedBytes: Int64
  let confidence: CleanupConfidence

  var id: String { tool.rawValue }
  var commandPreview: String {
    ([executable.path] + arguments).joined(separator: " ")
  }
}

struct DeveloperCommandResult: Sendable {
  let action: DeveloperCleanupAction
  let succeeded: Bool
  let message: String
}

struct DeveloperCleanupService: Sendable {
  func availableActions() -> [DeveloperCleanupAction] {
    let manager = FileManager.default
    let home = manager.homeDirectoryForCurrentUser
    let sizeService = CleanerService(homeURL: home)
    func size(_ relativePath: String) -> Int64 {
      (try? sizeService.size(of: home.appendingPathComponent(relativePath))) ?? 0
    }
    var actions: [DeveloperCleanupAction] = []
    if let xcrun = executable(named: "xcrun") {
      actions.append(
        .init(
          tool: .simulator, executable: xcrun,
          arguments: ["simctl", "delete", "unavailable"],
          detail: "Xóa simulator runtime không còn được Xcode hỗ trợ bằng simctl.",
          estimatedBytes: size("Library/Developer/CoreSimulator/Devices"), confidence: .safe))
    }
    if let docker = executable(named: "docker") {
      actions.append(
        .init(
          tool: .docker, executable: docker,
          arguments: ["system", "prune", "--force"],
          detail: "Dọn build cache, network và container đã dừng; không xóa volume.",
          estimatedBytes: size("Library/Containers/com.docker.docker/Data"), confidence: .review))
    }
    if let brew = executable(named: "brew") {
      actions.append(
        .init(
          tool: .homebrew, executable: brew, arguments: ["cleanup"],
          detail: "Dùng Homebrew để xóa download cũ và phiên bản package không còn cần thiết.",
          estimatedBytes: size("Library/Caches/Homebrew"), confidence: .safe))
    }
    if let npm = executable(named: "npm") {
      actions.append(
        .init(
          tool: .npm, executable: npm, arguments: ["cache", "clean", "--force"],
          detail: "Dùng npm để dọn cache có thể tải lại.",
          estimatedBytes: size(".npm/_cacache"), confidence: .review))
    }
    if let python = executable(named: "python3") {
      actions.append(
        .init(
          tool: .pip, executable: python, arguments: ["-m", "pip", "cache", "purge"],
          detail: "Dùng pip để dọn wheel và HTTP cache.",
          estimatedBytes: size("Library/Caches/pip"), confidence: .safe))
    }
    return actions
  }

  func run(_ action: DeveloperCleanupAction, timeout: TimeInterval = 120) -> DeveloperCommandResult
  {
    guard Self.allowedExecutableNames.contains(action.executable.lastPathComponent),
      Self.allowedArguments[action.tool] == action.arguments
    else {
      return DeveloperCommandResult(
        action: action, succeeded: false, message: "Command không nằm trong allowlist.")
    }
    let process = Process()
    process.executableURL = action.executable
    process.arguments = action.arguments
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    do {
      try process.run()
      let deadline = Date().addingTimeInterval(timeout)
      while process.isRunning, Date() < deadline {
        Thread.sleep(forTimeInterval: 0.1)
      }
      if process.isRunning {
        process.terminate()
        return DeveloperCommandResult(
          action: action, succeeded: false,
          message: "Command vượt quá giới hạn \(Int(timeout)) giây.")
      }
      return DeveloperCommandResult(
        action: action, succeeded: process.terminationStatus == 0,
        message: process.terminationStatus == 0
          ? "Command hoàn tất." : "Command kết thúc với mã \(process.terminationStatus).")
    } catch {
      return DeveloperCommandResult(
        action: action, succeeded: false, message: error.localizedDescription)
    }
  }

  private func executable(named name: String) -> URL? {
    let paths = [
      "/usr/bin/\(name)", "/bin/\(name)", "/usr/local/bin/\(name)",
      "/opt/homebrew/bin/\(name)",
    ]
    return paths.map(URL.init(fileURLWithPath:)).first {
      FileManager.default.isExecutableFile(atPath: $0.path)
    }
  }

  private static let allowedExecutableNames = Set(["xcrun", "docker", "brew", "npm", "python3"])
  private static let allowedArguments: [DeveloperCleanupTool: [String]] = [
    .simulator: ["simctl", "delete", "unavailable"],
    .docker: ["system", "prune", "--force"],
    .homebrew: ["cleanup"],
    .npm: ["cache", "clean", "--force"],
    .pip: ["-m", "pip", "cache", "purge"],
  ]
}

@MainActor
final class DeveloperCleanupViewModel: ObservableObject {
  @Published var actions: [DeveloperCleanupAction] = []
  @Published var isWorking = false
  @Published var status = ""
  @Published var errorMessage: String?
  private let service = DeveloperCleanupService()
  private let history = HistoryStore()

  func refresh() {
    actions = service.availableActions()
  }

  func run(_ action: DeveloperCleanupAction) {
    guard !isWorking else { return }
    isWorking = true
    status = "Đang chạy \(action.tool.rawValue)…"
    let service = service
    let history = history
    Task {
      let result = await Task.detached { service.run(action) }.value
      if result.succeeded {
        history.record(
          action: "Developer Cleanup: \(action.tool.rawValue)", paths: [action.commandPreview],
          bytes: action.estimatedBytes, recoverable: false,
          note: "Đã chạy command chính thức từ allowlist; không thể Undo từ Trash.")
        status = "\(action.tool.rawValue): hoàn tất"
      } else {
        errorMessage = result.message
        status = "\(action.tool.rawValue): thất bại"
      }
      actions = service.availableActions()
      isWorking = false
    }
  }
}
