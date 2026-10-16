import Foundation
import XCTest

@testable import MacinityMonitoring

final class UtilityTests: XCTestCase {
  func testCommandCatalogRejectsArgumentInjection() throws {
    XCTAssertFalse(UtilityCommand.validLabel("evil/path"))
    XCTAssertFalse(UtilityCommand.validLabel("a\nbootout"))
    XCTAssertFalse(UtilityCommand.validDisk("disk1;echo"))
    XCTAssertTrue(UtilityCommand.validDisk("disk12s2s1"))
    XCTAssertThrowsError(try UtilityCommand.processCommand(-1).read())
    XCTAssertFalse(PackageCommand.validPackage("--force"))
    XCTAssertFalse(PackageCommand.validPackage("."))
    XCTAssertFalse(PackageCommand.validPackage("/tmp/package"))
    XCTAssertFalse(PackageCommand.validPackage("x;rm"))
    XCTAssertTrue(PackageCommand.validPackage("@scope/package"))
  }
  func testLaunchctlStateSeparatesRegistrationFromRunning() {
    let parsed = StartupInventory.parseServices(
      "PID\tStatus\tLabel\n-\t0\tcom.example.idle\n123\t-9\tcom.example.running\n")
    XCTAssertNotNil(parsed["com.example.idle"])
    XCTAssertNil(parsed["com.example.idle"]?.pid)
    XCTAssertEqual(parsed["com.example.running"]?.pid, 123)
    XCTAssertEqual(parsed["com.example.running"]?.exit, "-9")
  }
  func testWiFiPayloadEscapesFieldsAndDoesNotLeakPasswordForOpenNetworks() throws {
    let qr = try WiFiUtilities.qrPayload(
      ssid: "test;S:other", password: "a\\b;:c", open: false, hidden: true)
    XCTAssertEqual(qr, "WIFI:T:WPA;S:test\\;S\\:other;P:a\\\\b\\;\\:c;H:true;;")
    XCTAssertFalse(
      try WiFiUtilities.qrPayload(ssid: "test", password: "secret", open: true, hidden: false)
        .contains("secret"))
    XCTAssertThrowsError(
      try WiFiUtilities.qrPayload(ssid: "", password: "pass", open: false, hidden: false))
  }
  func testPackageInventoriesKeepKindsAndVirtualEnvironmentBoundary() throws {
    let brew = try PackageInventory.parse(
      #"{"formulae":[{"full_name":"git","installed":[{"version":"1"}]}],"casks":[{"token":"example","installed":"2"}]}"#,
      tool: "brew")
    XCTAssertEqual(brew.entries.count, 2)
    XCTAssertTrue(brew.entries.first { $0.name == "example" }!.cask)
    let system = try PackageInventory.parse(
      #"{"prefix":"/usr","base_prefix":"/usr","packages":[]}"#, tool: "python3")
    XCTAssertFalse(system.isVirtualEnvironment)
    let venv = try PackageInventory.parse(
      #"{"prefix":"/venv","base_prefix":"/usr","packages":[{"name":"demo","version":"3"}]}"#,
      tool: "python3")
    XCTAssertTrue(venv.isVirtualEnvironment)
    XCTAssertEqual(venv.entries.first?.version, "3")
    XCTAssertThrowsError(try PackageInventory.parse("broken", tool: "npm"))
  }
  func testUnmountedDriveDoesNotOfferFinderOrInventFreeSpace() {
    let value = ExternalDriveInspection.parse(
      ["VolumeName": "", "MountPoint": "", "FreeSpace": 0, "Internal": false], id: "disk4")
    XCTAssertEqual(value.name, "disk4")
    XCTAssertNil(value.mount)
    XCTAssertNil(value.free)
    XCTAssertFalse(value.canEject)
  }
  func testDeviceParserOmitsSerialsAndRetainsBatteryWhenAvailable() throws {
    let data = Data(
      #"{"SPBluetoothDataType":[{"_name":"Headphones","battery_percent":80,"serial_number":"private","device_address":"private","connected":"Yes"}]}"#
        .utf8)
    let result = try DeviceInventory.parse(data)
    XCTAssertEqual(result.entries.count, 1)
    XCTAssertTrue(result.entries[0].fields.contains("Battery Percent: 80"))
    XCTAssertFalse(result.entries[0].fields.joined().contains("private"))
  }
  func testBluetoothGroupingDoesNotCreateNumericDevices() throws {
    let data = Data(
      #"{"SPBluetoothDataType":[{"device_not_connected":[{"_name":"Test accessory","device_batteryPercent":80},{"Second accessory":{"device_address":"private-value"}}]}]}"#
        .utf8)
    let inventory = try DeviceInventory.parse(data)
    XCTAssertEqual(inventory.entries.map(\.name), ["Test accessory", "Second Accessory"])
    XCTAssertFalse(inventory.entries.flatMap(\.fields).joined().contains("private-value"))
    XCTAssertTrue(inventory.entries[0].fields.contains("Connection: Not connected"))
  }

}
