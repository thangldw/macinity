import Darwin
import Foundation
import IOKit
import IOKit.ps

extension SystemMonitoringProvider {
  func readDiskCounters(at time: SampleTime) -> MetricSample<[IOCounter]> {
    var iterator: io_iterator_t = 0
    let result = IOServiceGetMatchingServices(
      kIOMainPortDefault, IOServiceMatching("IOBlockStorageDriver"), &iterator)
    guard result == KERN_SUCCESS else {
      return MetricSample(
        availability: .error, unit: .bytes, time: time, source: "IOBlockStorageDriver",
        reason: "IOKit status \(result)")
    }
    defer { IOObjectRelease(iterator) }
    var counters: [IOCounter] = []
    var missing = 0
    while true {
      let device = IOIteratorNext(iterator)
      if device == 0 { break }
      defer { IOObjectRelease(device) }
      var identity: UInt64 = 0
      guard IORegistryEntryGetRegistryEntryID(device, &identity) == KERN_SUCCESS,
        let stats = IORegistryEntryCreateCFProperty(
          device, "Statistics" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
          as? [String: Any],
        let read = stats["Bytes (Read)"] as? NSNumber,
        let write = stats["Bytes (Write)"] as? NSNumber, read.doubleValue >= 0,
        write.doubleValue >= 0
      else {
        missing += 1
        continue
      }
      counters.append(
        IOCounter(
          id: String(identity), name: "Device \(identity)", inputBytes: read.uint64Value,
          outputBytes: write.uint64Value))
    }
    return MetricSample(
      value: counters.isEmpty ? nil : counters.sorted { $0.id < $1.id },
      availability: counters.isEmpty ? .unsupported : .available, unit: .bytes, time: time,
      source: "IORegistry/IOBlockStorageDriver Statistics",
      reason: missing > 0
        ? "\(missing) storage devices lack readable byte counters; coverage is partial" : nil)
  }

  func readNetworkCounters(at time: SampleTime) -> MetricSample<[IOCounter]> {
    guard let bytes = SystemNetworkCounters.read() else {
      return MetricSample(
        availability: .temporarilyUnavailable, unit: .bytes, time: time,
        source: "sysctl/NET_RT_IFLIST2/if_data64", reason: "64-bit interface counters unavailable")
    }
    var interfaces: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&interfaces) == 0 else {
      return MetricSample(
        availability: .error, unit: .bytes, time: time, source: "getifaddrs",
        reason: "Interface enumeration failed")
    }
    defer { freeifaddrs(interfaces) }
    var counters: [IOCounter] = []
    var cursor = interfaces
    while let entry = cursor {
      defer { cursor = entry.pointee.ifa_next }
      guard entry.pointee.ifa_addr?.pointee.sa_family == UInt8(AF_LINK),
        let namePointer = entry.pointee.ifa_name
      else { continue }
      let name = String(cString: namePointer)
      let index = if_nametoindex(namePointer)
      guard let counter = bytes[index] else { continue }
      let isLoopback = (entry.pointee.ifa_flags & UInt32(IFF_LOOPBACK)) != 0
      let isUp = (entry.pointee.ifa_flags & UInt32(IFF_UP)) != 0
      // en* is the macOS physical Ethernet/Wi-Fi naming policy; tunnels/bridges stay separate.
      let aggregate = name.hasPrefix("en") && !isLoopback && isUp
      counters.append(
        IOCounter(
          id: "\(index):\(name)", name: name,
          inputBytes: counter.input, outputBytes: counter.output,
          includeInAggregate: aggregate))
    }
    return MetricSample(
      value: counters.sorted { $0.name < $1.name }, availability: .available, unit: .bytes,
      time: time, source: "getifaddrs identity; sysctl/NET_RT_IFLIST2/if_data64")
  }

  func readCapacity(at time: SampleTime) -> MetricSample<DiskCapacity> {
    do {
      let values = try URL(fileURLWithPath: "/").resourceValues(forKeys: [
        .volumeTotalCapacityKey, .volumeAvailableCapacityKey,
      ])
      guard let total = values.volumeTotalCapacity, let free = values.volumeAvailableCapacity,
        total > 0, free >= 0, free <= total
      else {
        return MetricSample(
          availability: .temporarilyUnavailable, unit: .bytes, time: time,
          source: "URLResourceValues/startup volume")
      }
      return MetricSample(
        value: DiskCapacity(totalBytes: UInt64(total), availableBytes: UInt64(free)),
        availability: .available, unit: .bytes, time: time,
        source: "URLResourceValues/startup volume")
    } catch {
      return MetricSample(
        availability: .error, unit: .bytes, time: time, source: "URLResourceValues/startup volume",
        reason: "Volume capacity read failed")
    }
  }

  func readBattery(at time: SampleTime) -> MetricSample<BatteryInfo> {
    guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
      let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
    else {
      return MetricSample(
        availability: .error, unit: .percent, time: time, source: "IOPowerSources")
    }
    let batteries = sources.compactMap { source -> [String: Any]? in
      guard
        let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue()
          as? [String: Any],
        description[kIOPSTransportTypeKey] as? String == kIOPSInternalType
      else { return nil }
      return description
    }
    guard !batteries.isEmpty else {
      return MetricSample(
        availability: .unsupported, unit: .percent, time: time, source: "IOPowerSources")
    }
    guard batteries.count == 1, let description = batteries.first,
      let current = description[kIOPSCurrentCapacityKey] as? NSNumber,
      let maximum = description[kIOPSMaxCapacityKey] as? NSNumber,
      let charging = description[kIOPSIsChargingKey] as? Bool,
      let state = description[kIOPSPowerSourceStateKey] as? String,
      state == kIOPSBatteryPowerValue || state == kIOPSACPowerValue,
      let battery = BatteryInfo(
        current: current.doubleValue, maximum: maximum.doubleValue,
        charging: charging, onBattery: state == kIOPSBatteryPowerValue)
    else {
      return MetricSample(
        availability: .temporarilyUnavailable, unit: .percent, time: time, source: "IOPowerSources",
        reason: "Battery fields are incomplete")
    }
    return MetricSample(
      value: battery, availability: .available, unit: .percent, time: time,
      source: "IOPowerSources/internal battery")
  }

  func readThermal(at time: SampleTime) -> MetricSample<ThermalLevel> {
    let thermal: ThermalLevel
    switch ProcessInfo.processInfo.thermalState {
    case .nominal: thermal = .nominal
    case .fair: thermal = .fair
    case .serious: thermal = .serious
    case .critical: thermal = .critical
    @unknown default: thermal = .unknown
    }
    return MetricSample(
      value: thermal, availability: thermal == .unknown ? .temporarilyUnavailable : .available,
      unit: .state, time: time, source: "ProcessInfo.thermalState")
  }

  func readSwap(at time: SampleTime) -> MetricSample<UInt64> {
    var usage = xsw_usage()
    var size = MemoryLayout<xsw_usage>.size
    let result = sysctlbyname("vm.swapusage", &usage, &size, nil, 0)
    return MetricSample(
      value: result == 0 ? usage.xsu_used : nil,
      availability: result == 0 ? .available : .error, unit: .bytes, time: time,
      source: "sysctl/vm.swapusage")
  }
}
