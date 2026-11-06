// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TidyBar",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "TidyBar", targets: ["TidyBar"])],
    targets: [
        .target(name: "TidyBarCore"),
        .target(name: "NativeMenuBar", linkerSettings: [.linkedFramework("Foundation")]),
        .executableTarget(name: "TidyBar", dependencies: ["TidyBarCore", "NativeMenuBar"]),
        .testTarget(name: "TidyBarCoreTests", dependencies: ["TidyBarCore"])
    ]
)
