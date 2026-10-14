import Foundation

public struct HealthValue: Codable, Sendable, Equatable, Identifiable {
  public let id: String
  public let title: String
  public let unit: String
  public let value: Double?
  public let availability: MetricAvailability
  public let source: String
  public let observedAt: Date

  public init(
    id: String, title: String, unit: String, value: Double?, availability: MetricAvailability,
    source: String, observedAt: Date
  ) {
    self.id = id
    self.title = title
    self.unit = unit
    self.value = value
    self.availability = availability
    self.source = source
    self.observedAt = observedAt
  }
}

public struct HealthRecord: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let observedAt: Date
  public let uptime: Double
  public let segment: UUID
  public let values: [HealthValue]
  public let pressure: String?
  public let thermal: String?

  public init(snapshot: MonitoringSnapshot, segment: UUID, now: Double) {
    id = UUID()
    observedAt = snapshot.time.wall
    uptime = snapshot.time.monotonic
    self.segment = segment
    func field<T>(
      _ metric: MetricSample<T>, id: String, title: String, unit: String,
      age: Double, value: Double?
    ) -> HealthValue {
      let state = metric.freshness(at: now, maximumAge: age)
      return HealthValue(
        id: id, title: title, unit: unit,
        value: state == .available ? value.flatMap { $0.isFinite ? $0 : nil } : nil,
        availability: state, source: metric.source, observedAt: metric.time.wall)
    }
    var fields = [
      field(
        snapshot.cpu, id: "cpu", title: "System CPU", unit: "%", age: 6,
        value: snapshot.cpu.value),
      field(
        snapshot.memory, id: "memory", title: "Occupied memory", unit: "%", age: 6,
        value: snapshot.memory.value?.occupiedPercent),
    ]
    let sensors = snapshot.hardware.reading.physicalSensors
    if let readings = sensors.value?.readings {
      for sensor in readings.prefix(34) {
        let state =
          sensors.freshness(at: now, maximumAge: 15) == .available
          ? sensor.availability : sensors.freshness(at: now, maximumAge: 15)
        fields.append(
          HealthValue(
            id: "smc:" + sensor.key, title: sensor.group + " • " + sensor.key,
            unit: sensor.unit.rawValue, value: state == .available ? sensor.value : nil,
            availability: state, source: sensors.source, observedAt: sensors.time.wall))
      }
    }
    values = fields
    let hardware = snapshot.hardware.reading
    pressure =
      hardware.pressure.freshness(at: now, maximumAge: 6) == .available
      ? hardware.pressure.value?.rawValue : nil
    thermal =
      hardware.thermal.freshness(at: now, maximumAge: 6) == .available
      ? hardware.thermal.value?.rawValue : nil
  }

  public init(
    observedAt: Date, uptime: Double, segment: UUID, values: [HealthValue],
    pressure: String? = nil, thermal: String? = nil
  ) {
    id = UUID()
    self.observedAt = observedAt
    self.uptime = uptime
    self.segment = segment
    self.values = values
    self.pressure = pressure
    self.thermal = thermal
  }
}

public struct HealthBaseline: Codable, Sendable, Equatable {
  public let capturedAt: Date
  public let records: [HealthRecord]
}

public struct HealthArchive: Codable, Sendable, Equatable {
  public var schemaVersion = 1
  public var records: [HealthRecord] = []
  public var omittedRecords = 0
  public var baseline: HealthBaseline?
  public init() {}
}

public struct HealthComparison: Sendable, Identifiable {
  public let id: String
  public let title: String
  public let unit: String
  public let baselineMedian: Double
  public let currentMedian: Double
  public let baselineCount: Int
  public let currentCount: Int
}

public enum HealthAnalysis {
  public static func comparisons(_ archive: HealthArchive) -> [HealthComparison] {
    guard let baseline = archive.baseline else { return [] }
    let current = Array(archive.records.filter { $0.observedAt > baseline.capturedAt }.suffix(60))
    func values(_ records: [HealthRecord], key: String, unit: String) -> [Double] {
      var seen: Set<Date> = []
      return records.compactMap { record in
        guard
          let metric = record.values.first(where: {
            $0.id == key && $0.unit == unit && $0.availability == .available
          }), seen.insert(metric.observedAt).inserted
        else { return nil }
        return metric.value.flatMap { $0.isFinite ? $0 : nil }
      }.sorted()
    }
    func median(_ values: [Double]) -> Double {
      let middle = values.count / 2
      return values.count.isMultiple(of: 2)
        ? (values[middle - 1] + values[middle]) / 2 : values[middle]
    }
    let definitions = baseline.records.flatMap(\.values).reduce(into: [String: HealthValue]()) {
      $0[$1.id] = $1
    }
    return definitions.values.sorted { $0.id < $1.id }.compactMap { definition in
      let a = values(baseline.records, key: definition.id, unit: definition.unit)
      let b = values(current, key: definition.id, unit: definition.unit)
      guard a.count >= 10, b.count >= 10 else { return nil }
      return HealthComparison(
        id: definition.id, title: definition.title, unit: definition.unit,
        baselineMedian: median(a), currentMedian: median(b), baselineCount: a.count,
        currentCount: b.count)
    }
  }
}

// Bounded, serialized local storage. A corrupt/unknown archive is preserved and blocks writes.
public actor HealthHistoryStore {
  public static let maximumRecords = 10_080
  private let url: URL
  private var archive = HealthArchive()
  private var loaded = false
  private var blocked = false
  public init(url: URL) { self.url = url }

  public func read(now: Date, retentionHours: Int) throws -> HealthArchive {
    if blocked { throw CocoaError(.fileReadCorruptFile) }
    if !loaded {
      do {
        if FileManager.default.fileExists(atPath: url.path) {
          let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
          guard size <= 24 * 1024 * 1024 else { throw CocoaError(.fileReadTooLarge) }
          let decoded = try JSONDecoder().decode(HealthArchive.self, from: Data(contentsOf: url))
          guard decoded.schemaVersion == 1, decoded.records.count <= Self.maximumRecords,
            decoded.omittedRecords >= 0,
            (decoded.baseline?.records.count ?? 0) <= 60,
            Set(decoded.records.map(\.id)).count == decoded.records.count,
            zip(decoded.records, decoded.records.dropFirst()).allSatisfy({
              $0.observedAt < $1.observedAt
            }),
            decoded.baseline?.capturedAt.timeIntervalSince1970.isFinite ?? true,
            (decoded.records + (decoded.baseline?.records ?? [])).allSatisfy(Self.valid)
          else { throw CocoaError(.fileReadCorruptFile) }
          archive = decoded
        }
        loaded = true
      } catch {
        blocked = true
        throw error
      }
    }
    prune(now: now, hours: retentionHours)
    return archive
  }

  public func append(_ record: HealthRecord, retentionHours: Int) throws -> HealthArchive {
    _ = try read(now: record.observedAt, retentionHours: retentionHours)
    guard Self.valid(record) else { throw CocoaError(.fileWriteInvalidFileName) }
    if let last = archive.records.last {
      guard record.observedAt > last.observedAt else { return archive }
      if record.observedAt.timeIntervalSince(last.observedAt) < 60 { return archive }
    }
    archive.records.append(record)
    prune(now: record.observedAt, hours: retentionHours)
    try save()
    return archive
  }

  public func captureBaseline(now: Date, retentionHours: Int) throws -> HealthArchive {
    _ = try read(now: now, retentionHours: retentionHours)
    let records = Array(archive.records.suffix(60))
    guard records.count >= 30 else { throw CocoaError(.validationMissingMandatoryProperty) }
    archive.baseline = HealthBaseline(capturedAt: now, records: records)
    try save()
    return archive
  }

  public func setRetention(now: Date, hours: Int) throws -> HealthArchive {
    _ = try read(now: now, retentionHours: hours)
    try save()
    return archive
  }

  private func prune(now: Date, hours: Int) {
    let cutoff = now.addingTimeInterval(-Double(hours == 24 ? 24 : 168) * 3600)
    archive.records = Array(
      archive.records.filter { $0.observedAt >= cutoff }
        .suffix(Self.maximumRecords))
    if let baseline = archive.baseline, baseline.capturedAt < cutoff { archive.baseline = nil }
  }
  private func save() throws {
    var data = try JSONEncoder().encode(archive)
    while data.count > 24 * 1024 * 1024 && !archive.records.isEmpty {
      let count = max(1, archive.records.count / 10)
      archive.records.removeFirst(count)
      archive.omittedRecords = min(Int.max - count, archive.omittedRecords) + count
      data = try JSONEncoder().encode(archive)
    }
    guard data.count <= 24 * 1024 * 1024 else { throw CocoaError(.fileWriteOutOfSpace) }
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true)
    try data.write(to: url, options: .atomic)
  }
  private static func valid(_ record: HealthRecord) -> Bool {
    record.observedAt.timeIntervalSince1970.isFinite && record.uptime.isFinite
      && record.uptime >= 0 && record.values.count <= 36
      && Set(record.values.map(\.id)).count == record.values.count
      && (record.pressure == nil || ["normal", "warning", "critical"].contains(record.pressure!))
      && (record.thermal == nil
        || ["nominal", "fair", "serious", "critical", "unknown"].contains(record.thermal!))
      && record.values.allSatisfy {
        $0.id.count <= 64 && $0.title.count <= 100 && $0.source.count <= 150
          && $0.observedAt.timeIntervalSince1970.isFinite && $0.unit.count <= 10
          && ($0.value?.isFinite ?? true)
          && ($0.availability == .available || $0.value == nil)
      }
  }
}
