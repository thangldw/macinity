// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Toolbox",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "ToolboxCore", targets: ["ToolboxCore"]),
    .library(name: "ToolboxStorage", targets: ["ToolboxStorage"]),
    .library(name: "ToolboxChanges", targets: ["ToolboxChanges"]),
    .library(name: "ToolboxMonitoring", targets: ["ToolboxMonitoring"]),
    .executable(name: "Toolbox", targets: ["Toolbox"]),
    .executable(name: "SmokeCore", targets: ["SmokeCore"]),
    .executable(name: "SmokeMonitoring", targets: ["SmokeMonitoring"]),
  ],
  targets: [
    .target(name: "ToolboxCore", path: "Sources/ToolboxCore"),
    .target(
      name: "ToolboxStorage", dependencies: ["ToolboxCore"], path: "Sources/ToolboxStorage"),
    .target(
      name: "ToolboxChanges", dependencies: ["ToolboxCore"], path: "Sources/ToolboxChanges"),
    .target(name: "ToolboxMonitoring", dependencies: ["ToolboxCore"]),
    .executableTarget(
      name: "Toolbox",
      dependencies: ["ToolboxCore", "ToolboxStorage", "ToolboxChanges", "ToolboxMonitoring"],
      path: "Sources/Toolbox"),
    .executableTarget(
      name: "SmokeCore", dependencies: ["ToolboxCore"], path: "Tests/SmokeCore"),
    .executableTarget(
      name: "SmokeMonitoring", dependencies: ["ToolboxMonitoring"], path: "Tests/SmokeMonitoring"),
    .testTarget(
      name: "ToolboxCoreTests", dependencies: ["ToolboxCore"], path: "Tests/ToolboxCoreTests",
      resources: [.copy("Fixtures")]),
    .testTarget(
      name: "ToolboxStorageTests", dependencies: ["ToolboxStorage"],
      path: "Tests/ToolboxStorageTests"),
    .testTarget(
      name: "ToolboxChangesTests", dependencies: ["ToolboxChanges"],
      path: "Tests/ToolboxChangesTests"),
    .testTarget(name: "ToolboxMonitoringTests", dependencies: ["ToolboxMonitoring"]),
    .testTarget(
      name: "ToolboxAppTests", dependencies: ["Toolbox"], path: "Tests/ToolboxAppTests"),
  ]
)
