import Foundation
import XCTest

@testable import ToolboxMonitoring

final class HardwareTests: XCTestCase {
  private func sample(_ counters: [IOCounter], time: Double) -> MetricSample<[IOCounter]> {
    MetricSample(
      value: counters, availability: .available, unit: .bytes,
      time: SampleTime(wall: Date(), monotonic: time), source: "fixture")
  }

  func testBatteryDetailsRejectSentinelsAndSeparateAdapterFromBatteryCapacity() {
    let missing = BatteryDetails(properties: [:])
    XCTAssertNil(missing.capacityRatio)
    let details = BatteryDetails(properties: [
      "CycleCount": 0, "Voltage": 12500, "ExternalConnected": true,
      "AdapterDetails": ["Watts": 65],
      "BatteryData": ["DesignCapacity": 6000, "NominalChargeCapacity": 5100],
    ])
    XCTAssertEqual(details.cycles, 0)
    XCTAssertEqual(details.capacityRatio, 85)
    XCTAssertEqual(details.voltage, 12.5)
    XCTAssertEqual(details.adapterWatts, 65)
    XCTAssertNil(
      BatteryDetails(properties: ["ExternalConnected": false, "AdapterDetails": ["Watts": 65]])
        .adapterWatts)
    XCTAssertNil(
      BatteryDetails(properties: [
        "BatteryData": ["DesignCapacity": 0, "NominalChargeCapacity": 5000]
      ]).capacityRatio)
    XCTAssertNil(
      BatteryInfo(
        current: 50, maximum: 100, charging: false, onBattery: true, minutesRemaining: 65535)?
        .minutesRemaining)
  }

  func testDeviceRatesWarmUpAndRetireMissingResetOrRecreatedInterfaces() {
    var tracker = CounterRateTracker()
    func counter(_ id: String, _ bytes: UInt64) -> IOCounter {
      IOCounter(id: id, name: id, inputBytes: bytes, outputBytes: bytes * 2)
    }
    XCTAssertNil(tracker.update(sample([counter("en0", 100)], time: 1)).value?.first?.input.value)
    let valid = tracker.update(sample([counter("en0", 300)], time: 3)).value?.first
    XCTAssertEqual(valid?.input.value, 100)
    XCTAssertEqual(valid?.output.value, 200)
    XCTAssertNil(tracker.update(sample([counter("en0", 1)], time: 4)).value?.first?.input.value)
    _ = tracker.update(sample([], time: 5))
    XCTAssertNil(tracker.update(sample([counter("en0", 500)], time: 6)).value?.first?.input.value)
    let changed = tracker.update(sample([counter("new-index:en0", 1000)], time: 7))
    XCTAssertNil(changed.value?.first?.input.value)
    XCTAssertNil(
      tracker.update(sample([counter("new-index:en0", 1100)], time: 7)).value?.first?.input.value)
    XCTAssertEqual(
      tracker.update(sample([counter("same", 0), counter("same", 0)], time: 8)).availability, .error
    )
  }

  func testPhysicalAggregateExcludesLoopbackAndTunnelAndDoesNotInventZero() {
    var tracker = CounterRateTracker()
    let first = [
      IOCounter(id: "en0", name: "en0", inputBytes: 100, outputBytes: 100),
      IOCounter(
        id: "utun0", name: "utun0", inputBytes: 100, outputBytes: 100, includeInAggregate: false),
    ]
    let time = SampleTime(wall: Date(), monotonic: 1)
    let raw = HardwareReading.unsupported(at: time)
    let warmingRates = tracker.update(sample(first, time: 1))
    let warm = HardwareSnapshot(disks: warmingRates, interfaces: warmingRates, reading: raw)
    XCTAssertNil(warm.aggregate(network: true, output: false).value)
    let second = [
      IOCounter(id: "en0", name: "en0", inputBytes: 300, outputBytes: 100),
      IOCounter(
        id: "utun0", name: "utun0", inputBytes: 5000, outputBytes: 9000, includeInAggregate: false),
    ]
    let rates = tracker.update(sample(second, time: 3))
    let snapshot = HardwareSnapshot(disks: rates, interfaces: rates, reading: raw)
    XCTAssertEqual(snapshot.aggregate(network: true, output: false).value, 100)
    XCTAssertEqual(snapshot.aggregate(network: true, output: true).value, 0)
  }

  func testBatteryRequiresCompleteValidRatio() {
    XCTAssertNil(BatteryInfo(current: 0, maximum: 0, charging: false, onBattery: false))
    XCTAssertNil(BatteryInfo(current: -1, maximum: 100, charging: false, onBattery: true))
    XCTAssertNil(BatteryInfo(current: 101, maximum: 100, charging: true, onBattery: false))
    XCTAssertEqual(
      BatteryInfo(current: 45, maximum: 90, charging: true, onBattery: false)?.percent, 50)
  }

  func testUnavailableCounterReadBreaksRateContinuity() {
    var tracker = CounterRateTracker()
    let counter = IOCounter(id: "disk", name: "disk", inputBytes: 10, outputBytes: 20)
    _ = tracker.update(sample([counter], time: 1))
    let failed = MetricSample<[IOCounter]>(
      availability: .error, unit: .bytes, time: SampleTime(wall: Date(), monotonic: 2),
      source: "fixture")
    XCTAssertEqual(tracker.update(failed).availability, .error)
    XCTAssertNil(tracker.update(sample([counter], time: 3)).value?.first?.input.value)
  }
}

@MainActor
final class HardwareDeviceTests: XCTestCase {
  func testPublicProvidersReadRealDeviceWithoutPrivilege() async {
    let provider = SystemMonitoringProvider()
    let time = SampleTime(wall: Date(), monotonic: ProcessInfo.processInfo.systemUptime)
    let aggregate = await provider.readAggregate(at: time)
    XCTAssertEqual(aggregate.cpu.availability, .available)
    XCTAssertEqual(aggregate.memory.value?.totalBytes, ProcessInfo.processInfo.physicalMemory)
    let hardware = await provider.readHardware(at: time)
    XCTAssertGreaterThan(hardware.capacity.value?.totalBytes ?? 0, 0)
    XCTAssertEqual(hardware.interfaces.availability, .available)
    XCTAssertEqual(hardware.thermal.availability, .available)
    if let battery = hardware.battery.value { XCTAssertTrue((0...100).contains(battery.percent)) }
    let process = await provider.readProcesses(at: time)
    XCTAssertTrue(
      process.observations.contains {
        $0.pid == ProcessInfo.processInfo.processIdentifier && $0.availability == .available
      })
    await provider.pauseHardware()
  }
}
