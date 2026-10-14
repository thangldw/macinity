import Darwin
import Foundation
import IOKit

public enum PhysicalSensorUnit: String, Sendable, Codable {
  case celsius = "°C"
  case rpm = "RPM"
  case watts = "W"
}

public struct PhysicalSensorReading: Sendable, Codable, Identifiable {
  public var id: String { key }
  public let key: String
  public let group: String
  public let unit: PhysicalSensorUnit
  public let value: Double?
  public let availability: MetricAvailability
  public let dataType: String?
}

public struct PhysicalSensorSnapshot: Sendable, Codable {
  public let readings: [PhysicalSensorReading]
  public let reportedFanCount: Int?
  public let mappingFamily: String
  public let coverageLimited: Bool
}

// AppleSMC's protocol is undocumented. Only fixed mapped keys are read; no key writes,
// arbitrary registry values, enumeration, fan controls or privileged helper are exposed.
public enum PhysicalSensors {
  public static func read(at time: SampleTime) -> MetricSample<PhysicalSensorSnapshot> {
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
    guard service != 0 else { return unavailable(.unsupported, time, "AppleSMC service absent") }
    defer { IOObjectRelease(service) }
    var connection: io_connect_t = 0
    let status = IOServiceOpen(service, mach_task_self_, 0, &connection)
    guard status == KERN_SUCCESS else {
      return unavailable(
        status == kIOReturnNotPrivileged || status == kIOReturnNotPermitted
          ? .permissionRequired : .error, time, "AppleSMC open status \(status)")
    }
    defer { IOServiceClose(connection) }
    let transport = SMCReadTransport(connection: connection)
    let mapping = mapping(for: processorName())
    let countValue = transport.read("FNum")
    let rawCount = countValue.flatMap { SMCScalar.decode(type: $0.type, bytes: $0.bytes) }
    let fanCount = rawCount.flatMap { $0 >= 0 && $0 <= 255 && $0.rounded() == $0 ? Int($0) : nil }
    var definitions = mapping.keys
    for index in 0..<min(fanCount ?? 0, 8) { definitions.append(("F\(index)Ac", "Fans", .rpm)) }
    definitions += [("TB0T", "Battery sensors", .celsius), ("PSTR", "System power", .watts)]
    let deadline = ProcessInfo.processInfo.systemUptime + 0.25
    var readings: [PhysicalSensorReading] = []
    for (key, group, unit) in definitions {
      guard !Task.isCancelled, ProcessInfo.processInfo.systemUptime <= deadline else {
        return unavailable(
          .temporarilyUnavailable, time, "SMC read cancelled or request budget exhausted")
      }
      let raw = transport.read(key)
      let decoded = raw.flatMap { SMCScalar.decode(type: $0.type, bytes: $0.bytes) }
      let supported = raw.map { SMCScalar.supports(type: $0.type, unit: unit) } ?? false
      let value = supported ? decoded.flatMap { SMCScalar.validated($0, unit: unit) } : nil
      readings.append(
        PhysicalSensorReading(
          key: key, group: group, unit: unit, value: value,
          availability: raw == nil
            ? .temporarilyUnavailable
            : (!supported || decoded == nil ? .unsupported : (value == nil ? .error : .available)),
          dataType: raw?.type))
    }
    return MetricSample(
      value: PhysicalSensorSnapshot(
        readings: readings,
        reportedFanCount: fanCount, mappingFamily: mapping.family, coverageLimited: true),
      availability: .available, unit: .collection, time: time,
      source: "AppleSMC/read-only mapped keys",
      reason:
        "Undocumented model-dependent mapping; missing keys and unknown physical locations remain unavailable"
    )
  }

  private static func unavailable(_ state: MetricAvailability, _ time: SampleTime, _ reason: String)
    -> MetricSample<PhysicalSensorSnapshot>
  {
    MetricSample(
      availability: state, unit: .collection, time: time, source: "AppleSMC/read-only",
      reason: reason)
  }

  static func mapping(for brand: String) -> (
    family: String, keys: [(String, String, PhysicalSensorUnit)]
  ) {
    let cpu: [String]
    let gpu: [String]
    let family: String
    let chip = brand.split(separator: " ").prefix(2).joined(separator: " ")
    if chip == "Apple M3" {
      family = "Apple M3"
      // Cross-checked iSMC M3 CPU e/p and GPU maps. Conflicting Tf fabric keys are
      // deliberately excluded from CPU; no physical-core numbering is inferred.
      cpu = [
        "Te05", "Te0H", "Te0P", "Te0S", "Te0U", "Te0L", "Tp05", "Tp0D", "Tp0L", "Tp0b", "Tp0h",
        "Tp0n", "Tp1F", "Tp1R",
      ]
      gpu = ["Tg05", "Tg0D", "Tg0L", "Tg01", "Tg0V", "Tg0v", "Tg13", "Tg1B"]
    } else if chip == "Apple M2" {
      family = "Apple M2"
      cpu = [
        "Tp1h", "Tp1t", "Tp1p", "Tp1l", "Tp01", "Tp05", "Tp09", "Tp0D", "Tp0H", "Tp0L", "Tp0P",
        "Tp0T",
      ]
      gpu = ["Tg0f", "Tg0j"]
    } else if chip == "Apple M1" {
      family = "Apple M1"
      cpu = ["Tp09", "Tp0T", "Tp01", "Tp05", "Tp0D", "Tp0H", "Tp0L", "Tp0P", "Tp0X", "Tp0b"]
      gpu = ["Tg05", "Tg0D", "Tg0L", "Tg0T"]
    } else if chip == "Apple M4" {
      family = "Apple M4"
      cpu = [
        "Te05", "Te0S", "Te09", "Te0H", "Tp01", "Tp05", "Tp09", "Tp0D", "Tp0H", "Tp0L", "Tp0P",
        "Tp0T",
      ]
      gpu = ["Tg0G", "Tg0H", "Tg1U", "Tg1k", "Tg0K", "Tg0L", "Tg0d", "Tg0e", "Tg0j", "Tg0k"]
    } else if brand.contains("Intel") {
      family = "Intel"
      cpu = ["TC0D", "TC0P", "TCAD"]
      gpu = ["TG0D", "TG0P", "TCGC"]
    } else {
      return ("Unknown", [])
    }
    // Group association follows published community maps. These are not physical core IDs.
    return (
      family, cpu.map { ($0, "CPU sensors", .celsius) } + gpu.map { ($0, "GPU sensors", .celsius) }
    )
  }

  private static func processorName() -> String {
    var size = 0
    guard sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0) == 0, size > 0, size <= 4096
    else { return "" }
    var bytes = [UInt8](repeating: 0, count: size)
    guard sysctlbyname("machdep.cpu.brand_string", &bytes, &size, nil, 0) == 0 else { return "" }
    return String(decoding: bytes.prefix(size).prefix(while: { $0 != 0 }), as: UTF8.self)
  }
}

// Packet offsets describe the 80-byte AppleSMC ABI, independent of Swift struct padding.
private struct SMCReadTransport {
  let connection: io_connect_t
  private enum Command: UInt8 {
    case metadata = 9
    case read = 5
  }
  func read(_ key: String) -> (type: String, bytes: [UInt8])? {
    guard key.utf8.count == 4, key.utf8.allSatisfy({ $0 >= 32 && $0 <= 126 }),
      let info = request(key, .metadata, size: 0)
    else { return nil }
    let size = word(info, 28)
    guard size > 0, size <= 32, let output = request(key, .read, size: size) else { return nil }
    let type = word(info, 32)
    guard
      let name = String(
        bytes: (0..<4).map { UInt8(truncatingIfNeeded: type >> (8 * (3 - $0))) }, encoding: .ascii)
    else { return nil }
    return (name, Array(output[48..<48 + Int(size)]))
  }
  private func request(_ key: String, _ command: Command, size: UInt32) -> [UInt8]? {
    var input = [UInt8](repeating: 0, count: 80)
    var output = input
    let code = key.utf8.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
    for index in 0..<4 {
      input[index] = UInt8(truncatingIfNeeded: code >> (8 * index))
      input[28 + index] = UInt8(truncatingIfNeeded: size >> (8 * index))
    }
    input[42] = command.rawValue
    var outputSize = 80
    let result = input.withUnsafeBytes { a in
      output.withUnsafeMutableBytes { b in
        IOConnectCallStructMethod(
          connection, 2, a.baseAddress, input.count, b.baseAddress, &outputSize)
      }
    }
    guard result == KERN_SUCCESS, outputSize == 80, output[40] == 0 else { return nil }
    return output
  }
  private func word(_ bytes: [UInt8], _ offset: Int) -> UInt32 {
    (0..<4).reduce(0) { $0 | UInt32(bytes[offset + $1]) << (8 * $1) }
  }
}

internal enum SMCScalar {
  static func supports(type: String, unit: PhysicalSensorUnit) -> Bool {
    switch unit {
    case .celsius: return ["flt ", "sp78"].contains(type)
    case .rpm: return ["flt ", "fpe2", "ui16"].contains(type)
    case .watts: return type == "flt "
    }
  }
  static func decode(type: String, bytes: [UInt8]) -> Double? {
    switch (type, bytes.count) {
    case ("flt ", 4):
      let bits = (0..<4).reduce(UInt32(0)) { $0 | UInt32(bytes[$1]) << (8 * $1) }
      return Double(Float(bitPattern: bits))
    case ("sp78", 2):
      return Double(Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1]))) / 256
    case ("fpe2", 2): return Double(UInt16(bytes[0]) << 8 | UInt16(bytes[1])) / 4
    case ("ui8 ", 1): return Double(bytes[0])
    case ("ui16", 2): return Double(UInt16(bytes[0]) << 8 | UInt16(bytes[1]))
    default: return nil
    }
  }
  static func validated(_ value: Double, unit: PhysicalSensorUnit) -> Double? {
    guard value.isFinite else { return nil }
    switch unit {
    case .celsius: return value > 0 && value <= 150 ? value : nil
    case .rpm: return value >= 0 && value <= 50_000 ? value : nil
    case .watts: return value >= 0 && value <= 5_000 ? value : nil
    }
  }
}
