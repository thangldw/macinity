import Foundation
import IOKit.pwr_mgt

public struct SleepRequest: Sendable, Identifiable {
  public let pid: Int32
  public let index: Int
  public let type: String
  public let name: String
  public let owner: ProcessMetadata?
  public var id: String { "\(pid):\(index)" }
}

public struct SleepInspection: Sendable {
  public let requests: [SleepRequest]
  public let omittedCount: Int
}

struct SleepAssertionParser {
  static func parse(
    _ assertions: [NSNumber: Any], before: [Int32: ProcessMetadata], access: any ProcessAccess
  ) -> SleepInspection {
    var requests: [SleepRequest] = []
    var omitted = 0
    for key in assertions.keys.sorted(by: { $0.int64Value < $1.int64Value }) {
      guard let pid = Int32(exactly: key.int64Value), pid > 0, key.doubleValue == Double(pid),
        let rows = assertions[key] as? [[String: Any]]
      else {
        omitted += 1
        continue
      }
      let initial = before[pid]
      let current = try? access.metadata(pid: pid)
      let owner = initial?.identity == current?.identity ? current : nil
      for (index, row) in rows.enumerated() {
        guard let level = row[kIOPMAssertionLevelKey] as? NSNumber else {
          omitted += 1
          continue
        }
        if level.doubleValue == Double(kIOPMAssertionLevelOff) { continue }
        guard level.doubleValue == Double(kIOPMAssertionLevelOn) else {
          omitted += 1
          continue
        }
        guard let type = row[kIOPMAssertionTypeKey] as? String, !type.isEmpty,
          requests.count < 512
        else {
          omitted += 1
          continue
        }
        requests.append(
          SleepRequest(
            pid: pid, index: index, type: String(type.prefix(256)),
            name: String((row[kIOPMAssertionNameKey] as? String ?? "").prefix(512)), owner: owner))
      }
    }
    return SleepInspection(requests: requests, omittedCount: omitted)
  }
}

extension SystemMonitoringProvider {
  public func readSleepRequests(at time: SampleTime) async -> MetricSample<SleepInspection> {
    // Capture identities before reading PID-keyed assertions; a later PID reuse cannot inherit ownership.
    let processes = await readProcesses(at: time)
    let before = Dictionary(
      processes.observations.compactMap { $0.metadata }.map { ($0.identity.pid, $0) },
      uniquingKeysWith: { first, _ in first })
    var raw: Unmanaged<CFDictionary>?
    let status = IOPMCopyAssertionsByProcess(&raw)
    let dictionary = raw?.takeRetainedValue()
    guard status == kIOReturnSuccess, let dictionary,
      let assertions = dictionary as? [NSNumber: Any]
    else {
      return MetricSample(
        availability: status == kIOReturnNotPrivileged ? .permissionRequired : .error,
        unit: .collection, time: time, source: "IOPMCopyAssertionsByProcess",
        reason: "Power assertion inspection failed (\(status))")
    }
    return MetricSample(
      value: SleepAssertionParser.parse(assertions, before: before, access: SystemProcessAccess()),
      availability: .available, unit: .collection, time: time, source: "IOPMCopyAssertionsByProcess"
    )
  }
}
