// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Termer",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Termer")
    ]
)
