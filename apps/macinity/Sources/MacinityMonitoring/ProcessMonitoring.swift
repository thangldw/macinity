import Darwin
import Foundation

public struct ProcessIdentity: Sendable, Hashable {
  public let pid: Int32
  public let startSeconds: UInt64
  public let startMicroseconds: UInt64

  public init(pid: Int32, startSeconds: UInt64, startMicroseconds: UInt64) {
    self.pid = pid
    self.startSeconds = startSeconds
    self.startMicroseconds = startMicroseconds
  }
  public var startDate: Date {
    Date(timeIntervalSince1970: Double(startSeconds) + Double(startMicroseconds) / 1_000_000)
  }
}

public struct ProcessMetadata: Sendable {
  public let identity: ProcessIdentity
  public let name: String
  public let parentPID: Int32
  public init(identity: ProcessIdentity, name: String, parentPID: Int32) {
    self.identity = identity
    self.name = name
    self.parentPID = parentPID
  }
}

public struct ProcessCounters: Sendable {
  public let cpuTicks: UInt64
  public let residentBytes: UInt64
  public let threadCount: Int32
  public init(cpuTicks: UInt64, residentBytes: UInt64, threadCount: Int32) {
    self.cpuTicks = cpuTicks
    self.residentBytes = residentBytes
    self.threadCount = threadCount
  }
}

public enum ProcessReadError: Error, Sendable {
  case permissionRequired, exited, identityChanged, unavailable
  public var availability: MetricAvailability {
    switch self {
    case .permissionRequired: .permissionRequired
    case .exited, .identityChanged: .temporarilyUnavailable
    case .unavailable: .error
    }
  }
}

public protocol ProcessAccess: Sendable {
  func metadata(pid: Int32) throws -> ProcessMetadata
  func counters(pid: Int32) throws -> ProcessCounters
}

public struct SystemProcessAccess: ProcessAccess {
  public init() {}
  private func failure() -> ProcessReadError {
    switch errno {
    case EPERM, EACCES: .permissionRequired
    case ESRCH, ENOENT: .exited
    default: .unavailable
    }
  }
  public func metadata(pid: Int32) throws -> ProcessMetadata {
    var bsd = proc_bsdinfo()
    let size = Int32(MemoryLayout<proc_bsdinfo>.size)
    guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bsd, size) == size else { throw failure() }
    guard bsd.pbi_start_tvsec > 0, bsd.pbi_pid == UInt32(pid) else {
      throw ProcessReadError.unavailable
    }
    let name = withUnsafeBytes(of: bsd.pbi_name) {
      String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self)
    }
    let command = withUnsafeBytes(of: bsd.pbi_comm) {
      String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self)
    }
    return ProcessMetadata(
      identity: ProcessIdentity(
        pid: pid, startSeconds: bsd.pbi_start_tvsec, startMicroseconds: bsd.pbi_start_tvusec),
      name: name.isEmpty ? command : name, parentPID: Int32(bsd.pbi_ppid))
  }
  public func counters(pid: Int32) throws -> ProcessCounters {
    var task = proc_taskinfo()
    let size = Int32(MemoryLayout<proc_taskinfo>.size)
    guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &task, size) == size else { throw failure() }
    let sum = task.pti_total_user.addingReportingOverflow(task.pti_total_system)
    guard !sum.overflow else { throw ProcessReadError.unavailable }
    return ProcessCounters(
      cpuTicks: sum.partialValue, residentBytes: task.pti_resident_size,
      threadCount: task.pti_threadnum)
  }
}

public struct ProcessObservation: Sendable {
  public let pid: Int32
  public let metadata: ProcessMetadata?
  public let counters: ProcessCounters?
  public let availability: MetricAvailability
  public let reason: String?
}

public struct ProcessInspector: Sendable {
  private let access: any ProcessAccess
  public init(access: any ProcessAccess = SystemProcessAccess()) { self.access = access }
  public func inspect(pid: Int32, expected: ProcessIdentity? = nil) -> ProcessObservation {
    var metadata: ProcessMetadata?
    do {
      let before = try access.metadata(pid: pid)
      if let expected, expected != before.identity { throw ProcessReadError.identityChanged }
      metadata = before
      let counters = try access.counters(pid: pid)
      let after = try access.metadata(pid: pid)
      guard before.identity == after.identity else { throw ProcessReadError.identityChanged }
      return ProcessObservation(
        pid: pid, metadata: after, counters: counters, availability: .available, reason: nil)
    } catch {
      let error = error as? ProcessReadError ?? .unavailable
      return ProcessObservation(
        pid: pid, metadata: metadata, counters: nil, availability: error.availability,
        reason: String(describing: error))
    }
  }
}

public enum ProcessRowID: Sendable, Hashable {
  case verified(ProcessIdentity)
  case restricted(Int32)
}

public struct ProcessSample: Sendable, Identifiable {
  public var id: ProcessRowID { identity.map { .verified($0) } ?? .restricted(pid) }
  public let pid: Int32
  public let identity: ProcessIdentity?
  public let name: String
  public let parentPID: Int32?
  public let cpu: MetricSample<Double>
  public let memory: MetricSample<UInt64>
  public let threads: Int32?
  public let cpuHistory: [ProcessTrendPoint]
}

public struct ProcessTrendPoint: Sendable, Identifiable {
  public var id: Double { time.monotonic }
  public let time: SampleTime
  public let cpu: Double?
}

public struct ProcessReading: Sendable {
  public let observations: [ProcessObservation]
  public let availability: MetricAvailability
  public let reason: String?
  public let timebaseNumerator: UInt32
  public let timebaseDenominator: UInt32
  public init(
    observations: [ProcessObservation], availability: MetricAvailability, reason: String? = nil,
    timebaseNumerator: UInt32 = 1, timebaseDenominator: UInt32 = 1
  ) {
    self.observations = observations
    self.availability = availability
    self.reason = reason
    self.timebaseNumerator = timebaseNumerator
    self.timebaseDenominator = timebaseDenominator
  }
}

public struct ProcessTracker: Sendable {
  private var previous: [ProcessIdentity: (ticks: UInt64, time: Double)] = [:]
  private var trends: [ProcessIdentity: RingBuffer<ProcessTrendPoint>] = [:]
  public init() {}
  public mutating func reset() {
    previous.removeAll()
    trends.removeAll()
  }

  public mutating func update(_ reading: ProcessReading, at time: SampleTime) -> [ProcessSample] {
    var next: [ProcessIdentity: (ticks: UInt64, time: Double)] = [:]
    var samples: [ProcessSample] = reading.observations.map { item in
      let identity = item.metadata?.identity
      var cpu: Double?
      if let identity, let counters = item.counters {
        if let before = previous[identity] {
          cpu = RateCalculator.processCPU(
            previous: before.ticks, current: counters.cpuTicks,
            elapsed: time.monotonic - before.time, numerator: reading.timebaseNumerator,
            denominator: reading.timebaseDenominator)
        }
        next[identity] = (counters.cpuTicks, time.monotonic)
      }
      return ProcessSample(
        pid: item.pid, identity: identity, name: item.metadata?.name ?? "PID \(item.pid)",
        parentPID: item.metadata?.parentPID,
        cpu: MetricSample(
          value: cpu,
          availability: item.availability == .available
            ? (cpu == nil ? .loading : .available) : item.availability,
          unit: .percent, time: time, source: "proc_pidinfo/PROC_PIDTASKINFO; mach_timebase_info",
          reason: item.reason),
        memory: MetricSample(
          value: item.counters?.residentBytes, availability: item.availability,
          unit: .bytes, time: time, source: "proc_pidinfo/PROC_PIDTASKINFO", reason: item.reason),
        threads: item.counters?.threadCount, cpuHistory: [])
    }
    previous = next
    // Only the top 100 verified consumers own short-term trends; exits retire identities.
    let tracked = Set(
      samples.sorted { ($0.cpu.value ?? -1) > ($1.cpu.value ?? -1) }.prefix(100).compactMap(
        \.identity))
    trends = trends.filter { tracked.contains($0.key) }
    for sample in samples {
      guard let identity = sample.identity, tracked.contains(identity) else { continue }
      var ring = trends[identity] ?? RingBuffer(capacity: 30)
      ring.append(ProcessTrendPoint(time: time, cpu: sample.cpu.value))
      trends[identity] = ring
    }
    samples = samples.map { sample in
      ProcessSample(
        pid: sample.pid, identity: sample.identity, name: sample.name,
        parentPID: sample.parentPID, cpu: sample.cpu, memory: sample.memory,
        threads: sample.threads,
        cpuHistory: sample.identity.flatMap {
          trends[$0]?.elements.filter { time.monotonic - $0.time.monotonic <= 60 }
        } ?? [])
    }
    return samples
  }
}

public enum ProcessOrdering: String, CaseIterable, Sendable {
  case cpu, memory, name, pid
  public func sorted(_ processes: [ProcessSample], query: String = "") -> [ProcessSample] {
    processes.filter {
      query.isEmpty || $0.name.localizedCaseInsensitiveContains(query)
        || String($0.pid).contains(query)
    }
    .sorted { left, right in
      switch self {
      case .cpu:
        if left.cpu.value != right.cpu.value {
          return (left.cpu.value ?? -1) > (right.cpu.value ?? -1)
        }
      case .memory:
        if left.memory.value != right.memory.value {
          return (left.memory.value ?? 0) > (right.memory.value ?? 0)
        }
      case .name:
        let order = left.name.localizedStandardCompare(right.name)
        if order != .orderedSame { return order == .orderedAscending }
      case .pid: break
      }
      return left.pid < right.pid
    }
  }
}
