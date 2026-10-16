import Foundation
import MacinityMonitoring

struct DiagnosticInsight: Identifiable, Equatable {
  let id: String
  let title: String
  let explanation: String
  let evidence: String
  let section: MacinitySection
}

enum DiagnosticInsights {
  static func evaluate(_ snapshot: MonitoringSnapshot?, now: Double, active: Bool)
    -> [DiagnosticInsight]
  {
    guard active, let snapshot, now >= snapshot.time.monotonic,
      now - snapshot.time.monotonic <= 6
    else { return [] }
    var result: [DiagnosticInsight] = []
    let pressure = snapshot.hardware.reading.pressure
    if pressure.freshness(at: now, maximumAge: 6) == .available,
      let level = pressure.value, level != .normal
    {
      result.append(
        .init(
          id: "memory", title: "Memory pressure needs attention",
          explanation:
            "macOS reports memory pressure. Occupied memory alone does not establish a problem.",
          evidence: level.rawValue, section: .cpuMemory))
    }
    let currentGeneration = snapshot.history.last?.generation
    let points = snapshot.history.suffix(31)
    if snapshot.cpu.freshness(at: now, maximumAge: 3) == .available,
      let first = points.first, let last = points.last,
      last.time.monotonic - first.time.monotonic >= 30,
      now - last.time.monotonic <= 3,
      points.allSatisfy({
        $0.generation == currentGeneration && ($0.cpuPercent ?? -1).isFinite
          && ($0.cpuPercent ?? -1) >= 85 && ($0.cpuPercent ?? -1) <= 100
      }),
      zip(points, points.dropFirst()).allSatisfy({
        let interval = $1.time.monotonic - $0.time.monotonic
        return interval > 0 && interval <= 2.5
      })
    {
      result.append(
        .init(
          id: "cpu", title: "Sustained CPU activity",
          explanation:
            "System CPU stayed at or above 85% for at least 30 seconds. Review the measured processes before attributing a cause.",
          evidence: "≥85% · ≥30s", section: .processes))
    }
    let capacity = snapshot.hardware.reading.capacity
    if capacity.freshness(at: now, maximumAge: 30) == .available,
      let value = capacity.value, value.totalBytes > 0,
      value.availableBytes <= value.totalBytes,
      Double(value.availableBytes) / Double(value.totalBytes) < 0.1
    {
      result.append(
        .init(
          id: "storage", title: "Startup volume is nearly full",
          explanation:
            "Available space is below 10% of reported capacity. APFS volumes share container space; inspect coverage and snapshots before cleanup.",
          evidence: monitoringBytes(value.availableBytes) + " / "
            + monitoringBytes(value.totalBytes),
          section: .storage))
    }
    let thermal = snapshot.hardware.reading.thermal
    if thermal.freshness(at: now, maximumAge: 6) == .available,
      let level = thermal.value, level == .serious || level == .critical
    {
      result.append(
        .init(
          id: "thermal", title: "Elevated thermal state",
          explanation:
            "macOS reports thermal pressure. This is an OS state, not a temperature measurement or proof of a particular app's impact.",
          evidence: level.rawValue, section: .batteryThermal))
    }
    return result
  }
}

enum LocalDiagnosticsReport {
  static func encode(_ snapshot: MonitoringSnapshot?, active: Bool, includeProcessNames: Bool)
    throws -> Data
  {
    let now = ProcessInfo.processInfo.systemUptime
    var report: [String: Any] = [
      "schemaVersion": 1, "generatedAt": ISO8601DateFormatter().string(from: Date()),
      "samplingActive": active, "processNamesIncluded": includeProcessNames,
      "scope":
        "Recent monitoring only; no dedicated path, username, hostname, network endpoint or scan-store fields. Process names default off; opt-in names may contain identifying text.",
    ]
    guard let snapshot else {
      report["availability"] = "loading"
      return try JSONSerialization.data(
        withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
    }
    report["observedAt"] = ISO8601DateFormatter().string(from: snapshot.time.wall)
    func metric<T>(_ sample: MetricSample<T>, age: Double, value: Any?) -> [String: Any] {
      var field: [String: Any] = [
        "availability": active
          ? sample.freshness(at: now, maximumAge: age).rawValue : "stale", "source": sample.source,
      ]
      if let value { field["observedValue"] = value }
      return field
    }
    report["cpuPercent"] = metric(snapshot.cpu, age: 3, value: snapshot.cpu.value)
    report["occupiedMemoryPercent"] = metric(
      snapshot.memory, age: 3,
      value: snapshot.memory.value?.occupiedPercent)
    report["availableBytes"] = metric(
      snapshot.hardware.reading.capacity, age: 30,
      value: snapshot.hardware.reading.capacity.value?.availableBytes)
    report["memoryPressure"] = metric(
      snapshot.hardware.reading.pressure, age: 6,
      value: snapshot.hardware.reading.pressure.value?.rawValue)
    report["thermalState"] = metric(
      snapshot.hardware.reading.thermal, age: 6,
      value: snapshot.hardware.reading.thermal.value?.rawValue)
    report["processesAvailability"] =
      active
      ? snapshot.processes.freshness(at: now, maximumAge: 6).rawValue : "stale"
    report["processes"] = Array(
      (snapshot.processes.value ?? []).sorted {
        ($0.cpu.value ?? -1) > ($1.cpu.value ?? -1)
      }.prefix(100)
    ).map { process -> [String: Any] in
      var fields: [String: Any] = [
        "pid": process.pid,
        "cpuAvailability":
          (active
          ? process.cpu.freshness(at: now, maximumAge: 6)
          : (process.cpu.availability == .available ? .stale : process.cpu.availability)).rawValue,
        "memoryAvailability":
          (active
          ? process.memory.freshness(at: now, maximumAge: 6)
          : (process.memory.availability == .available ? .stale : process.memory.availability))
          .rawValue,
      ]
      if let cpu = process.cpu.value { fields["cpuOneCorePercent"] = cpu }
      if let memory = process.memory.value { fields["residentBytes"] = memory }
      if includeProcessNames { fields["name"] = process.name }
      return fields
    }
    report["history"] = snapshot.history.suffix(60).map { point -> [String: Any] in
      var fields: [String: Any] = [
        "observedAt": ISO8601DateFormatter().string(from: point.time.wall),
        "generation": point.generation,
      ]
      if let cpu = point.cpuPercent { fields["cpuPercent"] = cpu }
      if let memory = point.memoryPercent { fields["occupiedMemoryPercent"] = memory }
      return fields
    }
    return try JSONSerialization.data(
      withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
  }
}
