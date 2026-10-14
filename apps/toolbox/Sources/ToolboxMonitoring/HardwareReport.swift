import Foundation

public enum HardwareReport {
  public static func encode(
    _ profile: HardwareProfile, snapshot: MonitoringSnapshot?, active: Bool, since: Double?
  ) throws -> Data {
    struct Report: Encodable {
      let schemaVersion = 1
      let profile: HardwareProfile
      let samplingActive: Bool
      let latestSampleAt: Date?
      let rangeResetMonotonic: Double?
      let range: [SensorExtrema]
      let physicalSensors: PhysicalSensorSnapshot?
      let physicalSensorObservedAt: Date?
      let physicalSensorAvailability: MetricAvailability
      let physicalSensorRange: [String: PhysicalSensorExtrema]
      let scope =
        "Latest generation, at most60 seconds/60 points; missing readings excluded; slow I/O counted only when sampled. No serial, hostname, paths, process names or network endpoints. Physical sensor keys use limited community AppleSMC mappings; temperatures/RPM/power are observations, not calibrated physical core identity or safety claims. No voltage, live clocks, SPD, SMART, fan control or benchmark."
    }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    let physical = snapshot?.hardware.reading.physicalSensors
    let ranges = Dictionary(
      uniqueKeysWithValues: (physical?.value?.readings ?? []).map {
        ($0.key, SensorWindow.physicalExtrema(snapshot?.history ?? [], sensor: $0, since: since))
      })
    return try encoder.encode(
      Report(
        profile: profile, samplingActive: active,
        latestSampleAt: snapshot?.time.wall, rangeResetMonotonic: since,
        range: SensorWindow.extrema(snapshot?.history ?? [], since: since),
        physicalSensors: physical?.value, physicalSensorObservedAt: physical?.time.wall,
        physicalSensorAvailability: physical?.availability ?? .loading, physicalSensorRange: ranges)
    )
  }
}
