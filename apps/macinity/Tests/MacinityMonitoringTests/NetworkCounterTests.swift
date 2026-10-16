import Darwin
import Foundation
import XCTest

@testable import MacinityMonitoring

final class NetworkCounterTests: XCTestCase {
  func testCounterRetainsBytesBeyond32BitRangeAndRejectsAmbiguousIdentity() {
    var header = if_msghdr2()
    header.ifm_msglen = UInt16(MemoryLayout<if_msghdr2>.size)
    header.ifm_version = UInt8(RTM_VERSION)
    header.ifm_type = UInt8(RTM_IFINFO2)
    header.ifm_index = 7
    header.ifm_data.ifi_ibytes = 5_000_000_000
    header.ifm_data.ifi_obytes = 9_000_000_000
    let data = withUnsafeBytes(of: header) { Data($0) }
    let decoded = SystemNetworkCounters.decode(data)
    XCTAssertEqual(decoded?[7]?.input, 5_000_000_000)
    XCTAssertEqual(decoded?[7]?.output, 9_000_000_000)
    XCTAssertNil(SystemNetworkCounters.decode(data + data))
    header.ifm_version = 0
    XCTAssertNil(SystemNetworkCounters.decode(withUnsafeBytes(of: header) { Data($0) }))
  }

  func testMalformedRouteMessagesCannotProducePartialOrOutOfBoundsCounters() {
    XCTAssertNil(SystemNetworkCounters.decode(Data([0, 0, 0, 0])))
    XCTAssertNil(SystemNetworkCounters.decode(Data([10, 0, 0, UInt8(RTM_IFINFO2)])))
    XCTAssertNil(SystemNetworkCounters.decode(Data([4, 0, 0, UInt8(RTM_IFINFO2)])))
    XCTAssertNil(SystemNetworkCounters.decode(Data([4, 0, 0, 0, 1])))
  }
}
