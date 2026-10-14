import Foundation

public protocol MonitoringClock: Sendable {
  func now() async -> SampleTime
  func sleep(seconds: Double) async throws
}

public struct SystemMonitoringClock: MonitoringClock {
  public init() {}
  public func now() -> SampleTime {
    SampleTime(wall: Date(), monotonic: ProcessInfo.processInfo.systemUptime)
  }
  public func sleep(seconds: Double) async throws {
    try await Task.sleep(for: .seconds(seconds))
  }
}

public enum MonitoringMode: Sendable, Equatable {
  case paused, active, menuBar
  var interval: Double { self == .menuBar ? 5 : 1 }
}

public actor MonitoringCoordinator {
  private let provider: any MonitoringProvider
  private let clock: any MonitoringClock
  private var task: Task<Void, Never>?
  private var generation = 0
  private var mode = MonitoringMode.paused
  private var diskTracker = CounterRateTracker()
  private var networkTracker = CounterRateTracker()
  private var hardware: HardwareSnapshot?
  private var lastHardwareTime: Double?
  private var processTracker = ProcessTracker()
  private var lastProcessTime: Double?
  private var processes: MetricSample<[ProcessSample]>?
  private var previousCPU: MetricSample<CPUTicks>?
  private var history = RingBuffer<TrendPoint>(capacity: 60)
  private var continuation: AsyncStream<MonitoringSnapshot>.Continuation?

  public init(
    provider: any MonitoringProvider = SystemMonitoringProvider(),
    clock: any MonitoringClock = SystemMonitoringClock()
  ) {
    self.provider = provider
    self.clock = clock
  }

  public func snapshots() -> AsyncStream<MonitoringSnapshot> {
    continuation?.finish()
    return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation = $0 }
  }

  public func setMode(_ newMode: MonitoringMode) async {
    if newMode == mode {
      if newMode == .paused { await task?.value }
      return
    }
    mode = newMode
    generation += 1
    let token = generation
    let oldTask = task
    oldTask?.cancel()
    // Join in-flight work before starting the next generation. Reentrant changes win.
    await oldTask?.value
    guard token == generation else { return }
    task = nil
    previousCPU = nil
    diskTracker.reset()
    networkTracker.reset()
    hardware = nil
    lastHardwareTime = nil
    await provider.pauseHardware()
    guard token == generation else { return }
    processTracker.reset()
    lastProcessTime = nil
    guard newMode != .paused else { return }
    task = Task { await self.run(token: token, interval: newMode.interval) }
  }

  public func inspectProcess(_ identity: ProcessIdentity) async -> ProcessObservation {
    await provider.inspectProcess(identity)
  }

  public func inspectSleepRequests() async -> MetricSample<SleepInspection> {
    await provider.readSleepRequests(at: clock.now())
  }

  public func stop() async {
    await setMode(.paused)
    continuation?.finish()
    continuation = nil
  }

  private func run(token: Int, interval: Double) async {
    while !Task.isCancelled && generation == token {
      let time = await clock.now()
      let reading = await provider.readAggregate(at: time)
      guard !Task.isCancelled, generation == token else { return }
      if lastProcessTime == nil
        || time.monotonic - (lastProcessTime ?? 0) >= (interval == 5 ? 5 : 2)
      {
        let processReading = await provider.readProcesses(at: time)
        guard !Task.isCancelled, generation == token else { return }
        processes = MetricSample(
          value: processReading.availability == .available
            ? processTracker.update(processReading, at: time) : nil,
          availability: processReading.availability, unit: .collection, time: time,
          source: "proc_listpids; proc_pidinfo", reason: processReading.reason)
        if processReading.availability != .available { processTracker.reset() }
        lastProcessTime = time.monotonic
      }
      if lastHardwareTime == nil
        || time.monotonic - (lastHardwareTime ?? 0) >= (interval == 5 ? 5 : 2)
      {
        let raw = await provider.readHardware(at: time)
        guard !Task.isCancelled, generation == token else { return }
        hardware = HardwareSnapshot(
          disks: diskTracker.update(raw.disks), interfaces: networkTracker.update(raw.interfaces),
          reading: raw)
        lastHardwareTime = time.monotonic
      }
      let hardwareSnapshot =
        hardware
        ?? HardwareSnapshot(
          disks: MetricSample(
            availability: .loading, unit: .bytesPerSecond, time: time, source: "IOKit"),
          interfaces: MetricSample(
            availability: .loading, unit: .bytesPerSecond, time: time, source: "getifaddrs"),
          reading: .unsupported(at: time))
      var cpuValue: Double?
      var state = reading.cpu.availability
      if let current = reading.cpu.value, state == .available {
        if let previous = previousCPU, let before = previous.value,
          reading.cpu.time.monotonic > previous.time.monotonic
        {
          cpuValue = RateCalculator.cpu(previous: before, current: current)
        }
        state = cpuValue == nil ? .loading : .available
        previousCPU = reading.cpu
      } else {
        previousCPU = nil
      }
      let cpu = MetricSample(
        value: cpuValue, availability: state, unit: .percent, time: reading.cpu.time,
        source: reading.cpu.source, reason: reading.cpu.reason)
      history.append(
        TrendPoint(
          time: time, generation: token, ioSampled: lastHardwareTime == time.monotonic,
          cpuPercent: cpuValue, memoryPercent: reading.memory.value?.occupiedPercent,
          networkInput: hardwareSnapshot.aggregate(network: true, output: false).value,
          networkOutput: hardwareSnapshot.aggregate(network: true, output: true).value,
          diskInput: hardwareSnapshot.aggregate(network: false, output: false).value,
          diskOutput: hardwareSnapshot.aggregate(network: false, output: true).value,
          physicalSensors: hardwareSnapshot.reading.physicalSensors.time.monotonic == time.monotonic
            ? hardwareSnapshot.reading.physicalSensors.value?.readings : nil))
      continuation?.yield(
        MonitoringSnapshot(
          time: time, cpu: cpu, memory: reading.memory,
          history: history.elements.filter { time.monotonic - $0.time.monotonic <= 60 },
          processes: processes
            ?? MetricSample(
              availability: .loading, unit: .collection, time: time, source: "proc_listpids"),
          hardware: hardwareSnapshot))
      do { try await clock.sleep(seconds: interval) } catch { return }
    }
  }
}
