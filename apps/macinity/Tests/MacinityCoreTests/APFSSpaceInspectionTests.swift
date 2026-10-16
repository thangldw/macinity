import Foundation
import XCTest

@testable import MacinityCore

final class APFSSpaceInspectionTests: XCTestCase {
  private func plist(_ value: [String: Any]) throws -> Data {
    try PropertyListSerialization.data(fromPropertyList: value, format: .xml, options: 0)
  }
  func testUnknownAndInvalidBytesStayUnknownWhileSnapshotFlagsRemainTyped() throws {
    let result = try APFSSpaceInspection.parse(
      info: plist(["APFSContainerSize": 100, "APFSContainerFree": 101, "CapacityInUse": true]),
      snapshots: plist([
        "Snapshots": [
          ["SnapshotName": "com.apple.TimeMachine.fixture", "Purgeable": true],
          ["Name": "com.apple.os.update.fixture", "Purgeable": 1],
        ]
      ]))
    XCTAssertEqual(result.containerTotal, 100)
    XCTAssertNil(result.containerFree)
    XCTAssertNil(result.volumeUsed)
    XCTAssertEqual(result.snapshots.map(\.purgeable), [true, nil])
    XCTAssertThrowsError(try APFSSpaceInspection.parse(info: plist([:]), snapshots: plist([:])))
    let empty = try APFSSpaceInspection.parse(info: plist([:]), snapshots: plist(["Snapshots": []]))
    XCTAssertTrue(empty.snapshots.isEmpty)
    XCTAssertNil(empty.containerTotal)
  }
  func testContainerAccountingUsesMatchingContainerAndRejectsIncompleteOrNegativeRemainder() throws
  {
    let info = try plist(["APFSContainerReference": "disk3"])
    let snapshots = try plist(["Snapshots": []])
    func containers(_ used: Any) throws -> Data {
      try plist([
        "Containers": [
          [
            "ContainerReference": "other", "CapacityCeiling": 999999, "CapacityFree": 1,
            "Volumes": [],
          ],
          [
            "ContainerReference": "disk3", "CapacityCeiling": 1000, "CapacityFree": 100,
            "Volumes": [
              ["Name": "Data", "CapacityInUse": 700], ["Name": "System", "CapacityInUse": used],
            ],
          ],
        ]
      ])
    }
    let result = try APFSSpaceInspection.parse(
      info: info, snapshots: snapshots, containers: containers(150))
    XCTAssertEqual(result.containerTotal, 1000)
    XCTAssertEqual(result.containerRemainder, 50)
    XCTAssertEqual(result.volumes.map(\.name), ["Data", "System"])
    for invalid in [201 as Any, true as Any, "unknown" as Any] {
      XCTAssertNil(
        try APFSSpaceInspection.parse(
          info: info, snapshots: snapshots,
          containers: containers(invalid)
        ).containerRemainder)
    }
  }

}
