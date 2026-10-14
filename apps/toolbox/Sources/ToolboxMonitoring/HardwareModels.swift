import Foundation

public struct IOCounter: Sendable, Equatable {
  public let id: String
  public let name: String
  public let inputBytes: UInt64
  public let outputBytes: UInt64
  public let includeInAggregate: Bool
  public init(
    id: String, name: String, inputBytes: UInt64, outputBytes: UInt64,
    includeInAggregate: Bool = true
  ) {
    self.id = id
    self.name = name
    self.inputBytes = inputBytes
    self.outputBytes = outputBytes
    self.includeInAggregate = includeInAggregate
  }
}

public struct IORate: Sendable, Identifiable {
  public let id: String
  public let name: String
  public let input: MetricSample<Double>
  public let output: MetricSample<Double>
  public let includeInAggregate: Bool
}

public struct CounterRateTracker: Sendable {
  private var previous: [String: (counter: IOCounter, time: Double)] = [:]
  public init() {}
  public mutating func reset() { previous.removeAll() }
  public mutating func update(_ sample: MetricSample<[IOCounter]>) -> MetricSample<[IORate]> {
    guard sample.availability == .available, let counters = sample.value else {
      reset()
      return MetricSample(
        availability: sample.availability, unit: .bytesPerSecond, time: sample.time,
        source: sample.source, reason: sample.reason)
    }
    guard Set(counters.map(\.id)).count == counters.count else {
      reset()
      return MetricSample(
        availability: .error, unit: .bytesPerSecond, time: sample.time, source: sample.source,
        reason: "Duplicate device identity")
    }
    var next: [String: (counter: IOCounter, time: Double)] = [:]
    let rates = counters.map { counter in
      var input: Double?
      var output: Double?
      if let before = previous[counter.id] {
        let elapsed = sample.time.monotonic - before.time
        input = RateCalculator.rate(
          previous: before.counter.inputBytes, current: counter.inputBytes, elapsed: elapsed)
        output = RateCalculator.rate(
          previous: before.counter.outputBytes, current: counter.outputBytes, elapsed: elapsed)
        if input == nil || output == nil {
          input = nil
          output = nil
        }
      }
      next[counter.id] = (counter, sample.time.monotonic)
      return IORate(
        id: counter.id, name: counter.name,
        input: MetricSample(
          value: input, availability: input == nil ? .loading : .available, unit: .bytesPerSecond,
          time: sample.time, source: sample.source),
        output: MetricSample(
          value: output, availability: output == nil ? .loading : .available, unit: .bytesPerSecond,
          time: sample.time, source: sample.source),
        includeInAggregate: counter.includeInAggregate)
    }
    previous = next
    return MetricSample(
      value: rates, availability: .available, unit: .bytesPerSecond, time: sample.time,
      source: sample.source, reason: sample.reason)
  }
}

public struct DiskCapacity: Sendable, Equatable {
  public let totalBytes: UInt64
  public let availableBytes: UInt64
  public init(totalBytes: UInt64, availableBytes: UInt64) {
    self.totalBytes = totalBytes
    self.availableBytes = availableBytes
  }
}

public struct BatteryInfo: Sendable, Equatable {
  public let percent: Double
  public let charging: Bool
  public let onBattery: Bool
  public init?(current: Double, maximum: Double, charging: Bool, onBattery: Bool) {
    guard current.isFinite, maximum.isFinite, maximum > 0, current >= 0, current <= maximum else {
      return nil
    }
    percent = current / maximum * 100
    self.charging = charging
    self.onBattery = onBattery
  }
}

public enum ThermalLevel: String, Sendable { case nominal, fair, serious, critical, unknown }
public enum MemoryPressureLevel: String, Sendable { case normal, warning, critical }

public struct HardwareReading: Sendable {
  public let disks: MetricSample<[IOCounter]>
  public let interfaces: MetricSample<[IOCounter]>
  public let capacity: MetricSample<DiskCapacity>
  public let battery: MetricSample<BatteryInfo>
  public let thermal: MetricSample<ThermalLevel>
  public let swap: MetricSample<UInt64>
  public let pressure: MetricSample<MemoryPressureLevel>
  public let physicalSensors: MetricSample<PhysicalSensorSnapshot>

  public init(
    disks: MetricSample<[IOCounter]>, interfaces: MetricSample<[IOCounter]>,
    capacity: MetricSample<DiskCapacity>, battery: MetricSample<BatteryInfo>,
    thermal: MetricSample<ThermalLevel>, swap: MetricSample<UInt64>,
    pressure: MetricSample<MemoryPressureLevel>,
    physicalSensors: MetricSample<PhysicalSensorSnapshot>? = nil
  ) {
    self.disks = disks
    self.interfaces = interfaces
    self.capacity = capacity
    self.battery = battery
    self.thermal = thermal
    self.swap = swap
    self.pressure = pressure
    self.physicalSensors =
      physicalSensors
      ?? MetricSample(
        availability: .unsupported, unit: .collection,
        time: thermal.time, source: "AppleSMC/read-only")
  }

  public static func unsupported(at time: SampleTime) -> HardwareReading {
    HardwareReading(
      disks: MetricSample(availability: .unsupported, unit: .bytes, time: time, source: "IOKit"),
      interfaces: MetricSample(
        availability: .unsupported, unit: .bytes, time: time, source: "getifaddrs"),
      capacity: MetricSample(
        availability: .unsupported, unit: .bytes, time: time, source: "URLResourceValues"),
      battery: MetricSample(
        availability: .unsupported, unit: .percent, time: time, source: "IOPowerSources"),
      thermal: MetricSample(
        availability: .unsupported, unit: .state, time: time, source: "ProcessInfo"),
      swap: MetricSample(availability: .unsupported, unit: .bytes, time: time, source: "sysctl"),
      pressure: MetricSample(
        availability: .unsupported, unit: .state, time: time, source: "DispatchSourceMemoryPressure"
      ))
  }
}

public struct HardwareSnapshot: Sendable {
  public let disks: MetricSample<[IORate]>
  public let interfaces: MetricSample<[IORate]>
  public let reading: HardwareReading

  public func aggregate(network: Bool, output: Bool) -> MetricSample<Double> {
    let sample = network ? interfaces : disks
    let rates = sample.value?.filter(\.includeInAggregate) ?? []
    let states = rates.map { output ? $0.output : $0.input }
    let value =
      !states.isEmpty && states.allSatisfy { $0.availability == .available }
      ? states.reduce(0) { $0 + ($1.value ?? 0) } : nil
    let availability: MetricAvailability =
      sample.availability != .available
      ? sample.availability
      : (rates.isEmpty ? .unsupported : (value == nil ? .loading : .available))
    return MetricSample(
      value: value, availability: availability, unit: .bytesPerSecond, time: sample.time,
      source: sample.source, reason: sample.reason)
  }
}
