import Foundation

public enum MetricAvailability: String, Sendable, CaseIterable, Codable {
  case loading, available, stale, unsupported, permissionRequired, temporarilyUnavailable, error
}

public enum MetricUnit: String, Sendable {
  case percent, bytes, bytesPerSecond, state, ticks, collection
}

public struct SampleTime: Sendable, Equatable {
  public let wall: Date
  public let monotonic: Double

  public init(wall: Date, monotonic: Double) {
    self.wall = wall
    self.monotonic = monotonic
  }
}

public struct MetricSample<Value: Sendable>: Sendable {
  public let value: Value?
  public let availability: MetricAvailability
  public let unit: MetricUnit
  public let time: SampleTime
  public let source: String
  public let reason: String?

  public init(
    value: Value? = nil, availability: MetricAvailability, unit: MetricUnit,
    time: SampleTime, source: String, reason: String? = nil
  ) {
    self.value = availability == .available || availability == .stale ? value : nil
    self.availability =
      availability == .available && value == nil ? .temporarilyUnavailable : availability
    self.unit = unit
    self.time = time
    self.source = source
    self.reason = reason
  }

  public func freshness(at now: Double, maximumAge: Double) -> MetricAvailability {
    guard availability == .available else { return availability }
    return now - time.monotonic > maximumAge || now < time.monotonic ? .stale : .available
  }
}

public struct CPUTicks: Sendable, Equatable {
  public let user: UInt64
  public let system: UInt64
  public let nice: UInt64
  public let idle: UInt64

  public init(user: UInt64, system: UInt64, nice: UInt64, idle: UInt64) {
    self.user = user
    self.system = system
    self.nice = nice
    self.idle = idle
  }
}

public struct MemoryInfo: Sendable, Equatable {
  public let totalBytes: UInt64
  public let freeBytes: UInt64
  public let wiredBytes: UInt64
  public let compressedBytes: UInt64

  // Non-free includes caches; this is not an estimate of reclaimable memory.
  public var occupiedPercent: Double? {
    guard totalBytes > 0, freeBytes <= totalBytes else { return nil }
    return Double(totalBytes - freeBytes) / Double(totalBytes) * 100
  }

  public init(totalBytes: UInt64, freeBytes: UInt64, wiredBytes: UInt64, compressedBytes: UInt64) {
    self.totalBytes = totalBytes
    self.freeBytes = freeBytes
    self.wiredBytes = wiredBytes
    self.compressedBytes = compressedBytes
  }
}

public struct AggregateReading: Sendable {
  public let cpu: MetricSample<CPUTicks>
  public let memory: MetricSample<MemoryInfo>

  public init(cpu: MetricSample<CPUTicks>, memory: MetricSample<MemoryInfo>) {
    self.cpu = cpu
    self.memory = memory
  }
}

public struct TrendPoint: Sendable, Identifiable {
  public var id: Double { time.monotonic }
  public let time: SampleTime
  public let generation: Int
  public let ioSampled: Bool
  public let cpuPercent: Double?
  public let memoryPercent: Double?
  public let networkInput: Double?
  public let networkOutput: Double?
  public let diskInput: Double?
  public let diskOutput: Double?
  public let physicalSensors: [PhysicalSensorReading]?

  public init(
    time: SampleTime, generation: Int, ioSampled: Bool, cpuPercent: Double?, memoryPercent: Double?,
    networkInput: Double?, networkOutput: Double?, diskInput: Double?, diskOutput: Double?,
    physicalSensors: [PhysicalSensorReading]? = nil
  ) {
    self.time = time
    self.generation = generation
    self.ioSampled = ioSampled
    self.cpuPercent = cpuPercent
    self.memoryPercent = memoryPercent
    self.networkInput = networkInput
    self.networkOutput = networkOutput
    self.diskInput = diskInput
    self.diskOutput = diskOutput
    self.physicalSensors = physicalSensors
  }
}

public struct MonitoringSnapshot: Sendable {
  public let time: SampleTime
  public let cpu: MetricSample<Double>
  public let memory: MetricSample<MemoryInfo>
  public let history: [TrendPoint]
  public let processes: MetricSample<[ProcessSample]>
  public let hardware: HardwareSnapshot
}
