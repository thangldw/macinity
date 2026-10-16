import Darwin
import Dispatch
import Foundation

public protocol MonitoringProvider: Sendable {
  func readAggregate(at time: SampleTime) async -> AggregateReading
  func readProcesses(at time: SampleTime) async -> ProcessReading
  func inspectProcess(_ identity: ProcessIdentity) async -> ProcessObservation
  func readHardware(at time: SampleTime) async -> HardwareReading
  func pauseHardware() async
  func readSleepRequests(at time: SampleTime) async -> MetricSample<SleepInspection>
}

extension MonitoringProvider {
  public func readSleepRequests(at time: SampleTime) async -> MetricSample<SleepInspection> {
    MetricSample(
      availability: .unsupported, unit: .collection, time: time, source: "IOPM assertions")
  }
  public func readHardware(at time: SampleTime) async -> HardwareReading { .unsupported(at: time) }
  public func pauseHardware() async {}
  public func inspectProcess(_ identity: ProcessIdentity) async -> ProcessObservation {
    ProcessObservation(
      pid: identity.pid, metadata: nil, counters: nil, availability: .unsupported, reason: nil)
  }
  public func readProcesses(at time: SampleTime) async -> ProcessReading {
    ProcessReading(observations: [], availability: .unsupported)
  }
}

public actor SystemMonitoringProvider: MonitoringProvider {
  private var cachedHardware: HardwareReading?
  private var pressureSource: (any DispatchSourceMemoryPressure)?
  private var pressure: MemoryPressureLevel?
  private var pressureTime: SampleTime?
  private var pressureGeneration = 0
  public init() {}

  public func pauseHardware() async {
    pressureGeneration += 1
    pressureSource?.setEventHandler {}
    pressureSource?.cancel()
    pressureSource = nil
    pressure = nil
    pressureTime = nil
    cachedHardware = nil
  }

  private func ensurePressureSource() {
    guard pressureSource == nil else { return }
    pressureGeneration += 1
    let token = pressureGeneration
    let source = DispatchSource.makeMemoryPressureSource(eventMask: .all)
    source.setEventHandler { [weak self] in
      let events = source.data
      let level: MemoryPressureLevel =
        events.contains(.critical) ? .critical : (events.contains(.warning) ? .warning : .normal)
      guard let provider = self else { return }
      Task { await provider.recordPressure(level, token: token) }
    }
    pressureSource = source
    source.resume()
  }

  private func recordPressure(_ level: MemoryPressureLevel, token: Int) {
    if token == pressureGeneration {
      pressure = level
      pressureTime = SampleTime(wall: Date(), monotonic: ProcessInfo.processInfo.systemUptime)
    }
  }

  public func readHardware(at time: SampleTime) async -> HardwareReading {
    ensurePressureSource()
    let old = cachedHardware
    let refreshSlow = old == nil || time.monotonic - (old?.capacity.time.monotonic ?? 0) >= 10
    let reading = HardwareReading(
      disks: readDiskCounters(at: time), interfaces: readNetworkCounters(at: time),
      capacity: refreshSlow ? readCapacity(at: time) : old!.capacity,
      battery: refreshSlow ? readBattery(at: time) : old!.battery,
      thermal: readThermal(at: time), swap: readSwap(at: time),
      pressure: MetricSample(
        value: pressure, availability: pressure == nil ? .temporarilyUnavailable : .available,
        unit: .state, time: pressureTime ?? time, source: "DispatchSourceMemoryPressure",
        reason: pressure == nil ? "No OS memory-pressure event observed" : nil),
      physicalSensors: refreshSlow ? PhysicalSensors.read(at: time) : old!.physicalSensors)
    cachedHardware = reading
    return reading
  }

  public func inspectProcess(_ identity: ProcessIdentity) async -> ProcessObservation {
    ProcessInspector().inspect(pid: identity.pid, expected: identity)
  }

  public func readProcesses(at time: SampleTime) async -> ProcessReading {
    let requested = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
    guard requested > 0 else {
      return ProcessReading(
        observations: [], availability: .error, reason: "Process enumeration failed")
    }
    // Bound enumeration, with headroom for processes created between the two calls.
    let capacity = min(Int(requested) / MemoryLayout<Int32>.size + 1024, 65536)
    var pids = [Int32](repeating: 0, count: capacity)
    let read = pids.withUnsafeMutableBytes {
      proc_listpids(UInt32(PROC_ALL_PIDS), 0, $0.baseAddress, Int32($0.count))
    }
    guard read > 0 else {
      return ProcessReading(
        observations: [], availability: .error, reason: "Process enumeration failed")
    }
    let truncated = Int(read) >= capacity * MemoryLayout<Int32>.size
    let inspector = ProcessInspector()
    var observations: [ProcessObservation] = []
    for pid in Set(pids.prefix(Int(read) / MemoryLayout<Int32>.size)).sorted() where pid > 0 {
      if Task.isCancelled { break }
      observations.append(inspector.inspect(pid: pid))
    }
    var timebase = mach_timebase_info_data_t()
    mach_timebase_info(&timebase)
    return ProcessReading(
      observations: observations, availability: .available,
      reason: truncated ? "Process list reached its 65,536-entry bound" : nil,
      timebaseNumerator: timebase.numer, timebaseDenominator: timebase.denom)
  }

  public func readAggregate(at time: SampleTime) async -> AggregateReading {
    let host = mach_host_self()
    defer { mach_port_deallocate(mach_task_self_, host) }
    var ticks = host_cpu_load_info()
    var count = mach_msg_type_number_t(
      MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
    let cpuStatus = withUnsafeMutablePointer(to: &ticks) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics(host, HOST_CPU_LOAD_INFO, $0, &count)
      }
    }
    let cpu = MetricSample(
      value: cpuStatus == KERN_SUCCESS
        ? CPUTicks(
          user: UInt64(ticks.cpu_ticks.0), system: UInt64(ticks.cpu_ticks.1),
          nice: UInt64(ticks.cpu_ticks.3), idle: UInt64(ticks.cpu_ticks.2)) : nil,
      availability: cpuStatus == KERN_SUCCESS ? .available : .error, unit: .ticks,
      time: time, source: "host_statistics/HOST_CPU_LOAD_INFO",
      reason: cpuStatus == KERN_SUCCESS ? nil : "Mach status \(cpuStatus)")

    var vm = vm_statistics64()
    var vmCount = mach_msg_type_number_t(
      MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
    let vmStatus = withUnsafeMutablePointer(to: &vm) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(vmCount)) {
        host_statistics64(host, HOST_VM_INFO64, $0, &vmCount)
      }
    }
    var pageSize: vm_size_t = 0
    let pageStatus = host_page_size(host, &pageSize)
    let totalBytes = ProcessInfo.processInfo.physicalMemory
    let freeBytes = UInt64(vm.free_count) * UInt64(pageSize)
    let memoryAvailable =
      vmStatus == KERN_SUCCESS && pageStatus == KERN_SUCCESS && pageSize > 0
      && totalBytes > 0 && freeBytes <= totalBytes
    let memory = MetricSample(
      value: memoryAvailable
        ? MemoryInfo(
          totalBytes: totalBytes,
          freeBytes: freeBytes,
          wiredBytes: UInt64(vm.wire_count) * UInt64(pageSize),
          compressedBytes: UInt64(vm.compressor_page_count) * UInt64(pageSize)) : nil,
      availability: memoryAvailable ? .available : .error, unit: .bytes,
      time: time, source: "host_statistics64/HOST_VM_INFO64; host_page_size",
      reason: memoryAvailable ? nil : "Mach status \(vmStatus)/\(pageStatus)")
    return AggregateReading(cpu: cpu, memory: memory)
  }
}
