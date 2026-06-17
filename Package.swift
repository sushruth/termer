// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Termer",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", branch: "main")
    ],
    targets: [
        .executableTarget(name: "Termer", resources: [.copy("AppIcon.icns")]),
        .executableTarget(name: "TermerRunner", dependencies: ["SwiftTerm"])
    ]
)
