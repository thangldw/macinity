// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Macinity",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "MacinityCore", targets: ["MacinityCore"]),
    .library(name: "MacinityStorage", targets: ["MacinityStorage"]),
    .library(name: "MacinityChanges", targets: ["MacinityChanges"]),
    .library(name: "MacinityMonitoring", targets: ["MacinityMonitoring"]),
    .executable(name: "Macinity", targets: ["Macinity"]),
    .executable(name: "SmokeCore", targets: ["SmokeCore"]),
    .executable(name: "SmokeMonitoring", targets: ["SmokeMonitoring"]),
  ],
  targets: [
    .target(name: "MacinityCore", path: "Sources/MacinityCore"),
    .target(
      name: "MacinityStorage", dependencies: ["MacinityCore"], path: "Sources/MacinityStorage"),
    .target(
      name: "MacinityChanges", dependencies: ["MacinityCore"], path: "Sources/MacinityChanges"),
    .target(name: "MacinityMonitoring", dependencies: ["MacinityCore"]),
    .executableTarget(
      name: "Macinity",
      dependencies: ["MacinityCore", "MacinityStorage", "MacinityChanges", "MacinityMonitoring"],
      path: "Sources/Macinity"),
    .executableTarget(
      name: "SmokeCore", dependencies: ["MacinityCore"], path: "Tests/SmokeCore"),
    .executableTarget(
      name: "SmokeMonitoring", dependencies: ["MacinityMonitoring"], path: "Tests/SmokeMonitoring"),
    .testTarget(
      name: "MacinityCoreTests", dependencies: ["MacinityCore"], path: "Tests/MacinityCoreTests",
      resources: [.copy("Fixtures")]),
    .testTarget(
      name: "MacinityStorageTests", dependencies: ["MacinityStorage"],
      path: "Tests/MacinityStorageTests"),
    .testTarget(
      name: "MacinityChangesTests", dependencies: ["MacinityChanges"],
      path: "Tests/MacinityChangesTests"),
    .testTarget(name: "MacinityMonitoringTests", dependencies: ["MacinityMonitoring"]),
    .testTarget(
      name: "MacinityAppTests", dependencies: ["Macinity"], path: "Tests/MacinityAppTests"),
  ]
)
