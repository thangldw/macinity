// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Changeora",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "Changeora", targets: ["Changeora"])
  ],
  targets: [
    .executableTarget(
      name: "Changeora",
      path: "Sources/Changeora"
    )
  ]
)
