import Foundation
import MacinityCore
import MacinityMonitoring

enum WeeklyReportText {
  static func render(_ summary: WeeklyReportSummary, language: String) -> String {
    let locale = AppLanguage(rawValue: language)?.locale ?? AppLanguage.defaultLanguage.locale
    func date(_ value: Date) -> String {
      value.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened).locale(locale))
    }
    func percent(_ value: Double) -> String { String(format: "%.0f%%", value) }
    func line(_ title: String, _ stat: WeeklyMetricStat?) -> String {
      guard let stat else { return "- " + L10n.text(title) + ": " + L10n.text("No data") }
      return "- " + L10n.text(title) + ": "
        + String(
          format: L10n.text("median %@ · 95th percentile %@ · peak %@ at %@"),
          percent(stat.median), percent(stat.p95), percent(stat.peak), date(stat.peakAt))
    }
    var lines = [
      "# " + L10n.text("Weekly Mac report"),
      date(summary.from) + " – " + date(summary.to),
      "",
      String(
        format: L10n.text("%d observations, about %d minutes of continuous coverage"),
        summary.observations, summary.continuousMinutes),
      "",
      line("System CPU", summary.cpu),
      line("Occupied memory", summary.memory),
      "- "
        + String(
          format: L10n.text("Memory pressure above normal: %d observations"),
          summary.elevatedPressureObservations),
      "- "
        + String(
          format: L10n.text("Thermal state serious or critical: %d observations"),
          summary.elevatedThermalObservations),
    ]
    if summary.dischargeMinutes > 0 {
      lines.append(
        "- "
          + String(
            format: L10n.text("Battery discharged for about %d minutes, observed drop %@"),
            summary.dischargeMinutes, percent(summary.dischargeDropPercent)))
    }
    if let lowest = summary.lowestBatteryPercent {
      lines.append("- " + String(format: L10n.text("Lowest battery level %@"), percent(lowest)))
    }
    lines += [
      "",
      L10n.text(
        "Periods without recording are gaps and are not estimated. Storage growth is tracked separately in Storage."
      ),
    ]
    return lines.joined(separator: "\n")
  }
}
