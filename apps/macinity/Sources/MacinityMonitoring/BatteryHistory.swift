import Foundation

/// Retains only health fields; serial numbers and scheduled power events are discarded.
public struct BatteryHealthReport: Sendable, Equatable {
  public let condition: String?
  public let maximumCapacity: Double?
  public let observedAt: Date

  public init(data: Data, observedAt: Date = Date()) throws {
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let batteries = (object?["SPPowerDataType"] as? [[String: Any]] ?? [])
      .filter { $0["_name"] as? String == "spbattery_information" }
    guard batteries.count == 1,
      let health = batteries[0]["sppower_battery_health_info"] as? [String: Any]
    else { throw CocoaError(.fileReadCorruptFile) }
    let raw = health["sppower_battery_health"] as? String
    condition = raw.flatMap { $0.count <= 80 && !$0.isEmpty ? $0 : nil }
    let capacity = health["sppower_battery_health_maximum_capacity"]
    let number: Double?
    if let value = capacity as? String {
      number = Double(
        value.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces))
    } else if let value = capacity as? NSNumber, CFGetTypeID(value) != CFBooleanGetTypeID() {
      number = value.doubleValue
    } else {
      number = nil
    }
    maximumCapacity = number.flatMap { $0.isFinite && (0...100).contains($0) ? $0 : nil }
    self.observedAt = observedAt
  }
  public static func read() throws -> Self {
    let result = try NetworkToolsProcess.read(.batteryHealth)
    guard result.status == 0 else { throw CocoaError(.fileReadUnknown) }
    return try Self(data: Data(result.text.utf8))
  }
}

public struct BatteryHistoryInterval: Sendable, Identifiable {
  public var id: Date { start }
  public let start: Date
  public var end: Date
  public let state: String
  public let startLevel: Double
  public var endLevel: Double
}

public enum BatteryHistoryAnalysis {
  /// Observed ranges only: never bridge sleep, stale samples, restarts or missing state.
  public static func intervals(_ records: [HealthRecord]) -> [BatteryHistoryInterval] {
    var result: [BatteryHistoryInterval] = []
    var previous: HealthRecord?
    var seen: Set<Date> = []
    for record in records.sorted(by: { $0.observedAt < $1.observedAt }) {
      func value(_ id: String) -> Double? {
        guard let field = record.values.first(where: { $0.id == id }),
          field.availability == .available, let number = field.value, number.isFinite
        else { return nil }
        return number
      }
      guard let level = value("battery.level"), (0...100).contains(level),
        let charging = value("battery.charging"), [0.0, 1.0].contains(charging),
        let onBattery = value("battery.onBattery"), [0.0, 1.0].contains(onBattery),
        !(charging == 1 && onBattery == 1),
        let time = record.values.first(where: { $0.id == "battery.level" })?.observedAt,
        seen.insert(time).inserted
      else {
        previous = nil
        continue
      }
      let state =
        charging == 1
        ? "Charging" : onBattery == 1 ? "Discharging" : "External power (not charging)"
      if let previous, previous.segment == record.segment,
        record.observedAt.timeIntervalSince(previous.observedAt) <= 90,
        record.observedAt > previous.observedAt, result.last?.state == state
      {
        result[result.count - 1].end = record.observedAt
        result[result.count - 1].endLevel = level
      } else {
        result.append(
          .init(
            start: record.observedAt, end: record.observedAt, state: state,
            startLevel: level, endLevel: level))
      }
      previous = record
    }
    return result
  }
}
