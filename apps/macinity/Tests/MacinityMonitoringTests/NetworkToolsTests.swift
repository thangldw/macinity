import XCTest

@testable import MacinityMonitoring

final class NetworkToolsTests: XCTestCase {
  func testTargetsRemainSingleValidatedHostArguments() {
    for value in ["example.com", "192.168.1.1", "::1", "fe80::1%en0"] {
      XCTAssertEqual(NetworkTarget.validate(value), value)
    }
    for value in [
      "", "-c", "https://example.com", "a;id", "$(id)", "a b", "user@host", "host:443", "::::",
      "::1%", "a..b", String(repeating: "a", count: 64) + ".com",
    ] {
      XCTAssertNil(NetworkTarget.validate(value), value)
    }
  }
  func testLossAndJitterKeepMissingRepliesAndDuplicateSequencesHonest() {
    let report = LatencyReport.parse(
      """
      64 bytes: icmp_seq=0 ttl=64 time=10.000 ms
      64 bytes: icmp_seq=0 ttl=64 time=99.000 ms (DUP!)
      64 bytes: icmp_seq=1 ttl=64 time=14.000 ms
      Request timeout for icmp_seq 2
      64 bytes: icmp_seq=3 ttl=64 time=30.000 ms
      4 packets transmitted, 3 packets received, 25.0% packet loss
      """, target: "fixture", exitStatus: 0)
    XCTAssertEqual(report.lossPercent, 25)
    XCTAssertEqual(report.meanMilliseconds, 18)
    XCTAssertEqual(report.jitterMilliseconds, 4)
    XCTAssertEqual(report.samples.count, 4)
    XCTAssertNil(report.samples[2].milliseconds)
    let failure = LatencyReport.parse(
      "ping: cannot resolve fixture", target: "fixture", exitStatus: 68)
    XCTAssertNil(failure.lossPercent)
    XCTAssertNil(failure.meanMilliseconds)
    XCTAssertNil(failure.jitterMilliseconds)
    XCTAssertTrue(failure.samples.isEmpty)
  }
  func testOverviewChangesIgnoreOrderingRedactionAndPartialCoverage() {
    func snapshot(_ time: Double, dns: [String], ssid: String? = "Network A", omitted: Int = 0)
      -> NetworkOverview
    {
      NetworkOverview(
        observedAt: Date(timeIntervalSince1970: time), adapters: [], primary: "en0",
        gateway4: "192.0.2.1", gateway6: nil, dns: dns,
        wifi: [
          .init(
            interface: "en0", ssid: ssid, bssid: nil, rssi: nil, noise: nil, channel: nil,
            band: nil, widthMHz: nil, transmitMbps: nil)
        ], omittedAdapters: omitted)
    }
    var changes = NetworkOverviewChanges()
    changes.consume(snapshot(1, dns: ["192.0.2.2", "192.0.2.3"]))
    changes.consume(snapshot(2, dns: ["192.0.2.3", "192.0.2.2"], ssid: nil))
    XCTAssertTrue(changes.events.isEmpty)
    changes.consume(snapshot(3, dns: ["192.0.2.4"]))
    XCTAssertEqual(changes.events.map(\.field), ["DNS servers"])
    changes.consume(snapshot(4, dns: ["192.0.2.5"], omitted: 1))
    changes.consume(snapshot(5, dns: ["192.0.2.6"]))
    XCTAssertEqual(changes.events.count, 1)
    changes.consume(snapshot(1000, dns: ["192.0.2.7"]))
    XCTAssertEqual(changes.events.count, 1)
    for i in 1...205 { changes.consume(snapshot(1000 + Double(i), dns: ["192.0.2.\(i)"])) }
    XCTAssertEqual(changes.events.count, 200)
    XCTAssertEqual(changes.omitted, 6)
    changes.clear()
    XCTAssertTrue(changes.events.isEmpty)
    XCTAssertEqual(changes.omitted, 0)
  }
  func testCarrierChangesAreIndependentOfInterfaceFlags() {
    func snapshot(_ time: Double, carrier: String?) -> NetworkOverview {
      let adapter = NetworkAdapter(
        name: "en1", kind: "Ethernet", active: true, addresses: [], mtu: 1500, received: nil,
        sent: nil, inputPackets: nil, outputPackets: nil, inputErrors: nil, outputErrors: nil,
        drops: nil, media: nil, carrier: carrier)
      return NetworkOverview(
        observedAt: Date(timeIntervalSince1970: time), adapters: [adapter], primary: nil,
        gateway4: nil, gateway6: nil, dns: [], wifi: [], omittedAdapters: 0)
    }
    var changes = NetworkOverviewChanges()
    changes.consume(snapshot(1, carrier: "inactive"))
    changes.consume(snapshot(2, carrier: "active"))
    XCTAssertEqual(changes.events.count, 1)
    XCTAssertEqual(changes.events.first?.field, "en1 • Carrier state")
    XCTAssertEqual(changes.events.first?.before, "No link detected")
    XCTAssertEqual(changes.events.first?.after, "Link detected")
    changes.consume(snapshot(3, carrier: nil))
    changes.consume(snapshot(4, carrier: "inactive"))
    XCTAssertEqual(changes.events.count, 1)
  }
  func testNumericDestinationSkipsDNSWithoutClaimingResolverHealth() async throws {
    let checks = try await Task.detached {
      try NetworkDiagnostics.connection(target: "127.0.0.1", gateway: nil)
    }.value
    XCTAssertEqual(checks.count, 3)
    XCTAssertNil(checks[0].succeeded)
    XCTAssertNil(checks[1].succeeded)
    XCTAssertEqual(checks[1].detail, "Not applicable to a numeric IP")
    XCTAssertEqual(checks[1].durationMilliseconds, 0)
    XCTAssertNotNil(checks[2].succeeded)
  }
  func testRealLoopbackProbeAndCancellationAtOwnedHelperBoundary() async throws {
    let report = try await Task.detached {
      try NetworkDiagnostics.latency(target: "127.0.0.1", count: 1)
    }.value
    XCTAssertEqual(report.exitStatus, 0)
    XCTAssertEqual(report.transmitted, 1)
    XCTAssertEqual(report.received, 1)
    XCTAssertEqual(report.lossPercent, 0)
    let start = ProcessInfo.processInfo.systemUptime
    let worker = Task.detached { try NetworkDiagnostics.latency(target: "127.0.0.1", count: 20) }
    try await Task.sleep(for: .milliseconds(150))
    worker.cancel()
    do {
      _ = try await worker.value
      XCTFail("Cancelled probe must not publish completion")
    } catch is CancellationError {}
    XCTAssertLessThan(ProcessInfo.processInfo.systemUptime - start, 3)
  }
}
