// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Toolbox",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "ToolboxCore", targets: ["ToolboxCore"]),
    .library(name: "ToolboxStorage", targets: ["ToolboxStorage"]),
    .library(name: "ToolboxChanges", targets: ["ToolboxChanges"]),
    .executable(name: "Toolbox", targets: ["Toolbox"]),
    .executable(name: "SmokeCore", targets: ["SmokeCore"]),
  ],
  targets: [
    .target(name: "ToolboxCore", path: "Sources/ToolboxCore"),
    .target(
      name: "ToolboxStorage", dependencies: ["ToolboxCore"], path: "Sources/ToolboxStorage"),
    .target(
      name: "ToolboxChanges", dependencies: ["ToolboxCore"], path: "Sources/ToolboxChanges"),
    .executableTarget(
      name: "Toolbox", dependencies: ["ToolboxCore", "ToolboxStorage", "ToolboxChanges"],
      path: "Sources/Toolbox"),
    .executableTarget(
      name: "SmokeCore", dependencies: ["ToolboxCore"], path: "Tests/SmokeCore"),
    .testTarget(
      name: "ToolboxCoreTests", dependencies: ["ToolboxCore"], path: "Tests/ToolboxCoreTests",
      resources: [.copy("Fixtures")]),
    .testTarget(
      name: "ToolboxStorageTests", dependencies: ["ToolboxStorage"],
      path: "Tests/ToolboxStorageTests"),
    .testTarget(
      name: "ToolboxChangesTests", dependencies: ["ToolboxChanges"],
      path: "Tests/ToolboxChangesTests"),
    .testTarget(
      name: "ToolboxAppTests", dependencies: ["Toolbox"], path: "Tests/ToolboxAppTests"),
  ]
)
