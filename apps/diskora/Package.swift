// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Diskora",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "Diskora", targets: ["Diskora"])
  ],
  targets: [
    .executableTarget(
      name: "Diskora",
      path: "Sources/Diskora"
    )
  ]
)
