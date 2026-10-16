import Foundation

public final class ScanActivityRegistry: @unchecked Sendable {
  public static let shared = ScanActivityRegistry()

  private let lock = NSLock()
  private var activeCount = 0

  public var isActive: Bool {
    lock.withLock { activeCount > 0 }
  }

  public func begin() {
    lock.withLock { activeCount += 1 }
  }

  public func end() {
    lock.withLock { activeCount = max(0, activeCount - 1) }
  }
}
