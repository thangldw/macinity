import Darwin
import Foundation
import Metal

public struct HardwareField: Sendable, Codable, Identifiable {
  public enum Unit: String, Sendable, Codable { case text, count, bytes, hertz }
  public let id: String
  public let section: String
  public let label: String
  public let value: String?
  public let unit: Unit
  public let source: String
}

public struct HardwareProfile: Sendable, Codable {
  public let observedAt: Date
  public let fields: [HardwareField]

  // A fixed sysctl/Metal inventory excludes serials, host names and registry dumps.
  public static func read() -> HardwareProfile {
    var fields: [HardwareField] = []
    func add(_ key: String, _ section: String, _ label: String, _ unit: HardwareField.Unit) {
      fields.append(
        HardwareField(
          id: key, section: section, label: label,
          value: unit == .text ? string(key) : integer(key).map(String.init),
          unit: unit, source: "sysctl/" + key))
    }
    add("hw.model", "System information", "Model identifier", .text)
    fields.append(
      HardwareField(
        id: "os", section: "System information", label: "Operating system",
        value: ProcessInfo.processInfo.operatingSystemVersionString, unit: .text,
        source: "ProcessInfo"))
    add("machdep.cpu.brand_string", "CPU", "Processor", .text)
    add("hw.machine", "CPU", "Hardware architecture", .text)
    add("hw.physicalcpu", "CPU", "Physical cores", .count)
    add("hw.logicalcpu", "CPU", "Logical processors", .count)
    add("hw.cpufrequency", "CPU", "Reported nominal frequency", .hertz)
    add("hw.memsize", "Memory", "Physical memory", .bytes)
    add("hw.pagesize", "Memory", "Page size", .bytes)
    add("hw.cachelinesize", "Cache", "Cache line size", .bytes)
    for (key, label) in [
      ("l1icachesize", "L1 instruction cache"), ("l1dcachesize", "L1 data cache"),
      ("l2cachesize", "L2 cache"), ("l3cachesize", "L3 cache"),
    ] {
      add("hw." + key, "Cache", label, .bytes)
    }
    let levels = min(max(integer("hw.nperflevels") ?? 0, 0), 8)
    for level in 0..<levels {
      let prefix = "hw.perflevel\(level)."
      let section = "CPU level \(level)"
      add(prefix + "name", section, "Performance level", .text)
      add(prefix + "physicalcpu", section, "Physical cores", .count)
      add(prefix + "logicalcpu", section, "Logical processors", .count)
      add(prefix + "l1icachesize", section, "L1 instruction cache", .bytes)
      add(prefix + "l1dcachesize", section, "L1 data cache", .bytes)
      add(prefix + "l2cachesize", section, "L2 cache", .bytes)
      add(prefix + "cpusperl2", section, "Cores sharing L2", .count)
    }
    for (index, device) in MTLCopyAllDevices().prefix(8).enumerated() {
      let section = "GPU \(index)"
      fields.append(
        HardwareField(
          id: "gpu\(index).name", section: section, label: "Metal device",
          value: device.name, unit: .text, source: "MTLDevice.name"))
      fields.append(
        HardwareField(
          id: "gpu\(index).unified", section: section, label: "Unified memory",
          value: device.hasUnifiedMemory ? "Yes" : "No", unit: .text,
          source: "MTLDevice.hasUnifiedMemory"))
      fields.append(
        HardwareField(
          id: "gpu\(index).workingSet", section: section,
          label: "Recommended GPU working set", value: String(device.recommendedMaxWorkingSetSize),
          unit: .bytes, source: "MTLDevice.recommendedMaxWorkingSetSize"))
    }
    return HardwareProfile(observedAt: Date(), fields: fields)
  }

  private static func string(_ key: String) -> String? {
    var size = 0
    guard sysctlbyname(key, nil, &size, nil, 0) == 0, size > 0, size <= 4096 else { return nil }
    var buffer = [UInt8](repeating: 0, count: size)
    guard sysctlbyname(key, &buffer, &size, nil, 0) == 0 else { return nil }
    let value = String(decoding: buffer.prefix(size).prefix(while: { $0 != 0 }), as: UTF8.self)
    return value.isEmpty ? nil : value
  }

  private static func integer(_ key: String) -> Int64? {
    var value: Int64 = 0
    var size = MemoryLayout<Int64>.size
    guard sysctlbyname(key, &value, &size, nil, 0) == 0 else { return nil }
    let result: Int64
    switch size {
    case 4: result = Int64(Int32(truncatingIfNeeded: value))
    case 8: result = value
    default: return nil
    }
    return result > 0 ? result : nil
  }
}
