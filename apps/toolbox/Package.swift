// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Toolbox",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "ToolboxCore", targets: ["ToolboxCore"]),
    .executable(name: "SmokeCore", targets: ["SmokeCore"]),
  ],
  targets: [
    .target(name: "ToolboxCore", path: "Sources/ToolboxCore"),
    .executableTarget(
      name: "SmokeCore", dependencies: ["ToolboxCore"], path: "Tests/SmokeCore"),
    .testTarget(
      name: "ToolboxCoreTests", dependencies: ["ToolboxCore"], path: "Tests/ToolboxCoreTests"),
  ]
)
