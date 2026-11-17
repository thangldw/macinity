import Foundation

public struct WeeklyMetricStat: Sendable, Equatable {
  public let median: Double
  public let p95: Double
  public let peak: Double
  public let peakAt: Date
  public let count: Int
}

/// Summary of recorded health history only. Gaps are never interpolated or estimated.
public struct WeeklyReportSummary: Sendable, Equatable {
  public let from: Date
  public let to: Date
  public let observations: Int
  public let continuousMinutes: Int
  public let cpu: WeeklyMetricStat?
  public let memory: WeeklyMetricStat?
  public let elevatedPressureObservations: Int
  public let elevatedThermalObservations: Int
  public let dischargeMinutes: Int
  public let dischargeDropPercent: Double
  public let lowestBatteryPercent: Double?
}

public enum WeeklyReport {
  static let maximumContinuousGap = 90.0

  public static func build(
    records: [HealthRecord], now: Date, days: Int = 7
  ) -> WeeklyReportSummary? {
    let from = now.addingTimeInterval(-Double(days) * 86_400)
    let window = records.filter { $0.observedAt >= from && $0.observedAt <= now }
      .sorted { $0.observedAt < $1.observedAt }
    guard !window.isEmpty else { return nil }

    var seconds = 0.0
    for (previous, record) in zip(window, window.dropFirst()) {
      let gap = record.observedAt.timeIntervalSince(previous.observedAt)
      if previous.segment == record.segment, gap > 0, gap <= maximumContinuousGap {
        seconds += gap
      }
    }

    let discharging = BatteryHistoryAnalysis.intervals(window).filter { $0.state == "Discharging" }
    let levels = window.compactMap { value($0, "battery.level") }

    return WeeklyReportSummary(
      from: from, to: now, observations: window.count,
      continuousMinutes: Int(seconds / 60),
      cpu: stat(window, id: "cpu"), memory: stat(window, id: "memory"),
      elevatedPressureObservations: window.count {
        $0.pressure == "warning" || $0.pressure == "critical"
      },
      elevatedThermalObservations: window.count {
        $0.thermal == "serious" || $0.thermal == "critical"
      },
      dischargeMinutes: Int(discharging.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) } / 60),
      dischargeDropPercent: discharging.reduce(0) { $0 + max(0, $1.startLevel - $1.endLevel) },
      lowestBatteryPercent: levels.min())
  }

  private static func value(_ record: HealthRecord, _ id: String) -> Double? {
    guard let field = record.values.first(where: { $0.id == id }),
      field.availability == .available, let number = field.value, number.isFinite
    else { return nil }
    return number
  }

  private static func stat(_ records: [HealthRecord], id: String) -> WeeklyMetricStat? {
    var seen: Set<Date> = []
    var points: [(Double, Date)] = []
    for record in records {
      guard let field = record.values.first(where: { $0.id == id }),
        field.availability == .available, let number = field.value, number.isFinite,
        seen.insert(field.observedAt).inserted
      else { continue }
      points.append((number, field.observedAt))
    }
    guard !points.isEmpty, let peak = points.max(by: { $0.0 < $1.0 }) else { return nil }
    let sorted = points.map(\.0).sorted()
    func rank(_ fraction: Double) -> Double {
      sorted[min(sorted.count - 1, max(0, Int(ceil(fraction * Double(sorted.count))) - 1))]
    }
    return WeeklyMetricStat(
      median: rank(0.5), p95: rank(0.95), peak: peak.0, peakAt: peak.1, count: sorted.count)
  }
}
