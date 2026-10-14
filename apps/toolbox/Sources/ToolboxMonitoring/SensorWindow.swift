import Foundation

public enum WindowSensor: String, Sendable, Codable, CaseIterable {
  case cpu, memory, diskRead, diskWrite, networkReceive, networkSend
  public var title: String {
    switch self {
    case .cpu: "System CPU • all cores"
    case .memory: "Occupied memory • includes caches"
    case .diskRead: "Disk read"
    case .diskWrite: "Disk write"
    case .networkReceive: "Network receive"
    case .networkSend: "Network send"
    }
  }
  public var isPercent: Bool { self == .cpu || self == .memory }
  func value(_ point: TrendPoint) -> Double? {
    switch self {
    case .cpu: point.cpuPercent
    case .memory: point.memoryPercent
    case .diskRead: point.ioSampled ? point.diskInput : nil
    case .diskWrite: point.ioSampled ? point.diskOutput : nil
    case .networkReceive: point.ioSampled ? point.networkInput : nil
    case .networkSend: point.ioSampled ? point.networkOutput : nil
    }
  }
}

public struct SensorExtrema: Sendable, Codable, Identifiable {
  public var id: String { sensor.rawValue }
  public let sensor: WindowSensor
  public let minimum: Double?
  public let maximum: Double?
  public let validSamples: Int
}

public enum SensorWindow {
  // Reuse the bounded engine history; gaps are absent values, not zeroes.
  // Hardware values reused between slow reads never count as new I/O observations.
  public static func extrema(_ history: [TrendPoint], since: Double? = nil) -> [SensorExtrema] {
    let latest = history.last
    let points = history.suffix(60).filter {
      guard let latest else { return false }
      return $0.generation == latest.generation && $0.time.monotonic <= latest.time.monotonic
        && $0.time.monotonic >= latest.time.monotonic - 60
        && (since == nil || $0.time.monotonic > since!)
    }
    return WindowSensor.allCases.map { sensor in
      let values = points.compactMap { sensor.value($0) }.filter {
        $0.isFinite && $0 >= 0 && (!sensor.isPercent || $0 <= 100)
      }
      return SensorExtrema(
        sensor: sensor, minimum: values.min(), maximum: values.max(), validSamples: values.count)
    }
  }
}

public struct PhysicalSensorExtrema: Sendable, Codable {
  public let minimum: Double?
  public let maximum: Double?
  public let validSamples: Int
}

extension SensorWindow {
  public static func physicalExtrema(
    _ history: [TrendPoint], sensor: PhysicalSensorReading,
    since: Double? = nil
  ) -> PhysicalSensorExtrema {
    guard let latest = history.last else {
      return PhysicalSensorExtrema(minimum: nil, maximum: nil, validSamples: 0)
    }
    let values = history.suffix(60).filter { point in
      point.generation == latest.generation && point.time.monotonic <= latest.time.monotonic
        && point.time.monotonic >= latest.time.monotonic - 60
        && (since.map { cutoff in point.time.monotonic > cutoff } ?? true)
    }.compactMap { point -> Double? in
      guard
        let reading = point.physicalSensors?.first(where: {
          $0.key == sensor.key && $0.unit == sensor.unit && $0.group == sensor.group
        }),
        reading.availability == .available, let value = reading.value
      else { return nil }
      return SMCScalar.validated(value, unit: sensor.unit)
    }
    return PhysicalSensorExtrema(
      minimum: values.min(), maximum: values.max(), validSamples: values.count)
  }
}
