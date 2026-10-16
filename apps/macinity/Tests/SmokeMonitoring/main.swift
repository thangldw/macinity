import Darwin
import Foundation
import MacinityCore
import MacinityMonitoring

private struct ProfileCheckpoint: Encodable {
  let durationSeconds: Double
  let averageOneCoreCPUPercent: Double
  let residentBytes: UInt64
}

private struct ProfileReport: Encodable {
  let mode: String
  let durationSeconds: Double
  let cpuSeconds: Double
  let averageOneCoreCPUPercent: Double
  let baselineResidentBytes: UInt64
  let peakResidentBytes: UInt64
  let incrementalResidentBytes: UInt64
  let samples: Int
  let checkpoints: [ProfileCheckpoint]
  let maximumHistoryCount: Int
  let maximumProcessCount: Int
  let cpuAvailability: String
  let diskAvailability: String
  let batteryAvailability: String
  let physicalSensorAvailability: String
  let physicalSensorObservations: Int
  let physicalSensorFailedObservations: Int
  let maximumPhysicalSensorCount: Int
  let os: String
  let architecture: String
}

private func resources() -> (cpu: Double, rss: UInt64) {
  var usage = rusage()
  getrusage(RUSAGE_SELF, &usage)
  let cpu =
    Double(usage.ru_utime.tv_sec + usage.ru_stime.tv_sec)
    + Double(usage.ru_utime.tv_usec + usage.ru_stime.tv_usec) / 1_000_000
  var task = proc_taskinfo()
  let bytes = Int32(MemoryLayout<proc_taskinfo>.size)
  let result = proc_pidinfo(getpid(), PROC_PIDTASKINFO, 0, &task, bytes)
  return (cpu, result == bytes ? task.pti_resident_size : 0)
}

@main
struct SmokeMonitoring {
  static func main() async {
    let arguments = Array(CommandLine.arguments.dropFirst())
    if arguments.first == "--nearby-wifi" {
      do {
        let scan = try NetworkOverviewProvider.scan()
        let output: [String: Any] = [
          "observedAt": ISO8601DateFormatter().string(from: scan.observedAt),
          "networks": scan.networks.count, "omitted": scan.omitted,
          "identityCoverage": scan.networks.filter { $0.ssid != nil }.count,
          "channelCoverage": scan.networks.filter { $0.channel != nil }.count,
          "RSSICoverage": scan.networks.filter { $0.rssi != nil }.count,
          "scope": "explicit CoreWLAN scan; identities not included",
        ]
        print(
          String(
            decoding: try JSONSerialization.data(
              withJSONObject: output, options: [.prettyPrinted, .sortedKeys]), as: UTF8.self))
      } catch {
        let error = error as NSError
        print("CoreWLAN scan unavailable: \(error.domain) code \(error.code)")
        exit(1)
      }
      return
    }
    if arguments.first == "--network-diagnostics", arguments.count == 2 {
      do {
        let target = arguments[1]
        guard let validated = NetworkTarget.validate(target), validated == target else { exit(64) }
        let checks = try NetworkDiagnostics.connection(target: target, gateway: nil)
        let latency = try NetworkDiagnostics.latency(target: target)
        let output: [String: Any] = [
          "target": target, "observedAt": ISO8601DateFormatter().string(from: Date()),
          "checks": checks.map {
            ["stage": $0.id, "status": $0.detail, "milliseconds": $0.durationMilliseconds]
              as [String: Any]
          },
          "ICMPExitStatus": latency.exitStatus, "transmitted": latency.transmitted ?? -1,
          "received": latency.received ?? -1, "lossPercent": latency.lossPercent ?? -1,
          "meanMilliseconds": latency.meanMilliseconds ?? -1,
          "jitterMilliseconds": latency.jitterMilliseconds ?? -1,
          "sampleCount": latency.samples.count,
          "scope": "explicit destination; no gateway probe in CLI; -1 denotes missing",
        ]
        print(
          String(
            decoding: try JSONSerialization.data(
              withJSONObject: output, options: [.prettyPrinted, .sortedKeys]), as: UTF8.self))
      } catch {
        fputs("Network diagnostic failed or timed out\n", stderr)
        exit(1)
      }
      return
    }
    if arguments.first == "--network-tools" {
      do {
        let value = try NetworkOverviewProvider.read()
        let loopback = try NetworkDiagnostics.latency(target: "127.0.0.1", count: 1)
        let output: [String: Any] = [
          "observedAt": ISO8601DateFormatter().string(from: value.observedAt),
          "adapters": value.adapters.count, "omittedAdapters": value.omittedAdapters,
          "wifiInterfaces": value.wifi.count,
          "ethernetInterfaces": value.adapters.filter { $0.kind == "Ethernet" }.count,
          "globalDNSCount": value.dns.count,
          "hasIPv4Gateway": value.gateway4 != nil, "hasIPv6Gateway": value.gateway6 != nil,
          "wifiRSSICoverage": value.wifi.filter { $0.rssi != nil }.count,
          "wifiNoiseCoverage": value.wifi.filter { $0.noise != nil }.count,
          "wifiChannelCoverage": value.wifi.filter { $0.channel != nil }.count,
          "wifiLinkRateCoverage": value.wifi.filter { $0.transmitMbps != nil }.count,
          "wifiIdentityCoverage": value.wifi.filter { $0.ssid != nil }.count,
          "loopbackExitStatus": loopback.exitStatus,
          "loopbackReceived": loopback.received ?? 0,
          "scope":
            "read-only observation and one local ICMP probe; no identities or addresses in report",
        ]
        print(
          String(
            decoding: try JSONSerialization.data(
              withJSONObject: output, options: [.prettyPrinted, .sortedKeys]), as: UTF8.self))
        if value.adapters.isEmpty || loopback.exitStatus != 0 { exit(1) }
      } catch {
        fputs("Network tool smoke failed\n", stderr)
        exit(1)
      }
      return
    }
    if arguments.first == "--physical-sensors" {
      let time = SampleTime(wall: Date(), monotonic: ProcessInfo.processInfo.systemUptime)
      let provider = SystemMonitoringProvider()
      let reading = await provider.readHardware(at: time)
      await provider.pauseHardware()
      let sample = reading.physicalSensors
      struct Report: Encodable {
        let availability: MetricAvailability
        let observedAt: Date
        let sensors: PhysicalSensorSnapshot?
        let elapsedSeconds: Double
        let reason: String?
      }
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      encoder.dateEncodingStrategy = .iso8601
      do {
        let bytes = try encoder.encode(
          Report(
            availability: sample.availability, observedAt: sample.time.wall,
            sensors: sample.value,
            elapsedSeconds: ProcessInfo.processInfo.systemUptime - time.monotonic,
            reason: sample.reason))
        print(String(decoding: bytes, as: UTF8.self))
      } catch {
        fputs("FAIL: physical sensor encoding\n", stderr)
        exit(1)
      }
      return
    }
    if arguments.first == "--system-inspection" {
      do {
        let sockets = try NetworkInspection.read()
        let dataVolume = try APFSSpaceInspection.read(volume: .data)
        let systemVolume = try APFSSpaceInspection.read(volume: .system)
        let report: [String: Any] = [
          "status": "PASS", "observedAt": ISO8601DateFormatter().string(from: Date()),
          "networkSockets": sockets.sockets.count,
          "networkVerifiedIdentities": sockets.sockets.filter { $0.identity != nil }.count,
          "networkOmitted": sockets.omitted,
          "dataSnapshots": dataVolume.snapshots.count,
          "systemSnapshots": systemVolume.snapshots.count,
          "containerVolumeCount": dataVolume.volumes.count,
          "containerRemainderBytes": dataVolume.containerRemainder.map { $0 as Any } ?? NSNull(),
          "containerCapacityBytes": dataVolume.containerTotal.map { $0 as Any } ?? NSNull(),
          "scope":
            "Actual bounded read-only helpers; aggregate evidence excludes socket endpoints and volume names",
          "os": ProcessInfo.processInfo.operatingSystemVersionString, "architecture": architecture,
        ]
        let bytes = try JSONSerialization.data(
          withJSONObject: report, options: [.sortedKeys, .prettyPrinted])
        print(String(decoding: bytes, as: UTF8.self))
        return
      } catch {
        fputs("FAIL: bounded system inspection: \(error)\n", stderr)
        exit(1)
      }
    }
    if arguments.first == "--sleep-inspection" {
      let engine = MonitoringCoordinator()
      let sample = await engine.inspectSleepRequests()
      guard sample.availability == .available, let inspection = sample.value,
        inspection.requests.count <= 512
      else {
        fputs("FAIL: public power assertion inspection\n", stderr)
        exit(1)
      }
      let report: [String: Any] = [
        "availability": sample.availability.rawValue,
        "requests": inspection.requests.count,
        "verifiedOwners": inspection.requests.filter { $0.owner != nil }.count,
        "omitted": inspection.omittedCount,
        "os": ProcessInfo.processInfo.operatingSystemVersionString,
        "architecture": architecture,
      ]
      guard let data = try? JSONSerialization.data(withJSONObject: report, options: [.sortedKeys])
      else { exit(1) }
      print(String(decoding: data, as: UTF8.self))
      return
    }
    let profiling = arguments.first == "--profile"
    let seconds = profiling ? (arguments.dropFirst().first.flatMap(Double.init) ?? 300) : 4
    guard seconds.isFinite, seconds >= 3, seconds <= 86_400 else {
      fputs("Duration must be between 3 and 86,400 seconds\n", stderr)
      exit(2)
    }
    let menuMode = arguments.contains("--menu-bar")
    let engine = MonitoringCoordinator()
    let start = ProcessInfo.processInfo.systemUptime
    let baseline = resources()
    var peak = baseline.rss
    var historyCount = 0
    var processCount = 0
    var sampleCount = 0
    var physicalObservations = 0
    var physicalFailures = 0
    var maximumPhysicalCount = 0
    var lastPhysicalTime: Double?
    var checkpoints: [ProfileCheckpoint] = []
    var nextCheckpoint = 300.0
    var last: MonitoringSnapshot?
    let stream = await engine.snapshots()
    await engine.setMode(menuMode ? .menuBar : .active)
    for await sample in stream {
      last = sample
      sampleCount += 1
      let physical = sample.hardware.reading.physicalSensors
      if lastPhysicalTime != physical.time.monotonic {
        lastPhysicalTime = physical.time.monotonic
        physicalObservations += 1
        if physical.availability != .available { physicalFailures += 1 }
        maximumPhysicalCount = max(maximumPhysicalCount, physical.value?.readings.count ?? 0)
      }
      peak = max(peak, resources().rss)
      historyCount = max(historyCount, sample.history.count)
      processCount = max(processCount, sample.processes.value?.count ?? 0)
      let elapsed = ProcessInfo.processInfo.systemUptime - start
      if elapsed >= nextCheckpoint {
        let measured = resources()
        checkpoints.append(
          ProfileCheckpoint(
            durationSeconds: elapsed,
            averageOneCoreCPUPercent: (measured.cpu - baseline.cpu) / elapsed * 100,
            residentBytes: measured.rss))
        nextCheckpoint += 300
      }
      if elapsed >= seconds { break }
    }
    await engine.stop()
    let end = resources()
    let elapsed = ProcessInfo.processInfo.systemUptime - start
    guard let last, last.cpu.availability == .available, last.memory.value?.totalBytes ?? 0 > 0,
      last.processes.availability == .available, historyCount <= 60
    else {
      fputs("FAIL: real monitoring, warm-up or capacity contract\n", stderr)
      exit(1)
    }
    if profiling {
      let report = ProfileReport(
        mode: menuMode ? "menuBar" : "active", durationSeconds: elapsed,
        cpuSeconds: end.cpu - baseline.cpu,
        averageOneCoreCPUPercent: (end.cpu - baseline.cpu) / elapsed * 100,
        baselineResidentBytes: baseline.rss, peakResidentBytes: peak,
        incrementalResidentBytes: peak - min(peak, baseline.rss), samples: sampleCount,
        checkpoints: checkpoints,
        maximumHistoryCount: historyCount, maximumProcessCount: processCount,
        cpuAvailability: last.cpu.availability.rawValue,
        diskAvailability: last.hardware.disks.availability.rawValue,
        batteryAvailability: last.hardware.reading.battery.availability.rawValue,
        physicalSensorAvailability: last.hardware.reading.physicalSensors.availability.rawValue,
        physicalSensorObservations: physicalObservations,
        physicalSensorFailedObservations: physicalFailures,
        maximumPhysicalSensorCount: maximumPhysicalCount,
        os: ProcessInfo.processInfo.operatingSystemVersionString,
        architecture: architecture)
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      do { print(String(decoding: try encoder.encode(report), as: UTF8.self)) } catch {
        fputs("Report encoding failed\n", stderr)
        exit(1)
      }
    } else {
      print(
        "PASS: live CPU/memory/process/hardware sampling, bounded history and clean cancellation")
    }
  }

  private static var architecture: String {
    #if arch(arm64)
      "arm64"
    #else
      "x86_64"
    #endif
  }
}
