import Foundation

enum CancellableWork {
  /// Runs blocking work off the caller's actor and forwards the caller's cancellation to it.
  /// A bare `Task.detached(...).value` does not inherit cancellation, so Stop would do nothing.
  static func run<T: Sendable>(
    priority: TaskPriority = .userInitiated, _ work: @escaping @Sendable () throws -> T
  ) async throws -> T {
    let task = Task.detached(priority: priority) { try work() }
    return try await withTaskCancellationHandler {
      try await task.value
    } onCancel: {
      task.cancel()
    }
  }
}
