import Foundation
import IOKit

public struct BatteryDetails: Sendable, Equatable {
  public let cycles: Int?
  public let designCapacity: Double?
  public let fullCapacity: Double?
  public let voltage: Double?
  public let adapterWatts: Double?
  public var capacityRatio: Double? {
    guard let designCapacity, let fullCapacity else { return nil }
    return fullCapacity / designCapacity * 100
  }

  init(properties: [String: Any]) {
    func number(_ source: [String: Any], _ key: String, maximum: Double) -> Double? {
      guard let number = source[key] as? NSNumber,
        CFGetTypeID(number) != CFBooleanGetTypeID()
      else { return nil }
      let value = number.doubleValue
      return value.isFinite && value > 0 && value <= maximum ? value : nil
    }
    let data = properties["BatteryData"] as? [String: Any] ?? [:]
    let cycle = (properties["CycleCount"] as? NSNumber)?.doubleValue
    cycles = cycle.flatMap {
      $0.isFinite && $0 >= 0 && $0 <= 100000 && $0.rounded() == $0 ? Int($0) : nil
    }
    designCapacity =
      number(data, "DesignCapacity", maximum: 100000)
      ?? number(properties, "DesignCapacity", maximum: 100000)
    fullCapacity =
      number(data, "NominalChargeCapacity", maximum: 100000)
      ?? number(properties, "AppleRawMaxCapacity", maximum: 100000)
    voltage = number(properties, "Voltage", maximum: 100000).map { $0 / 1000 }
    adapterWatts =
      (properties["ExternalConnected"] as? Bool) == true
      ? number(properties["AdapterDetails"] as? [String: Any] ?? [:], "Watts", maximum: 1000) : nil
  }

  static func read() -> Self {
    let service = IOServiceGetMatchingService(
      kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
    guard service != 0 else { return Self(properties: [:]) }
    defer { IOObjectRelease(service) }
    var properties: Unmanaged<CFMutableDictionary>?
    guard
      IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0)
        == KERN_SUCCESS,
      let values = properties?.takeRetainedValue() as? [String: Any]
    else { return Self(properties: [:]) }
    // Retain only numeric battery fields, never serials or the registry payload.
    return Self(properties: values)
  }
}
