import Foundation

public struct RingBuffer<Element: Sendable>: Sendable {
  private var slots: [Element?]
  private var next = 0
  public private(set) var count = 0
  public var capacity: Int { slots.count }

  public init(capacity: Int) {
    precondition(capacity > 0)
    slots = Array(repeating: nil, count: capacity)
  }

  public mutating func append(_ element: Element) {
    slots[next] = element
    next = (next + 1) % capacity
    count = min(count + 1, capacity)
  }

  public var elements: [Element] {
    let start = count == capacity ? next : 0
    return (0..<count).compactMap { slots[(start + $0) % capacity] }
  }
}

public enum RateCalculator {
  public static func rate(previous: UInt64, current: UInt64, elapsed: Double) -> Double? {
    guard elapsed.isFinite, elapsed > 0, current >= previous else { return nil }
    let result = Double(current - previous) / elapsed
    return result.isFinite ? result : nil
  }

  public static func cpu(previous: CPUTicks, current: CPUTicks) -> Double? {
    let before = [previous.user, previous.system, previous.nice, previous.idle]
    let after = [current.user, current.system, current.nice, current.idle]
    guard zip(before, after).allSatisfy({ $1 >= $0 }) else { return nil }
    let delta = zip(before, after).map { Double($1 - $0) }
    let total = delta.reduce(0, +)
    guard total > 0 else { return nil }
    return (delta[0] + delta[1] + delta[2]) / total * 100
  }

  public static func processCPU(
    previous: UInt64, current: UInt64, elapsed: Double, numerator: UInt32, denominator: UInt32
  ) -> Double? {
    guard denominator > 0, numerator > 0,
      let ticksPerSecond = rate(previous: previous, current: current, elapsed: elapsed)
    else { return nil }
    let result = ticksPerSecond * Double(numerator) / Double(denominator) / 1_000_000_000 * 100
    return result.isFinite ? result : nil
  }
}
