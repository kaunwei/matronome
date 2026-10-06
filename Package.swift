// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Metronome",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MetronomeCore",
            targets: ["MetronomeCore"]
        ),
        .executable(
            name: "MetronomeApp",
            targets: ["MetronomeApp"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MetronomeCore",
            dependencies: [],
            path: "Sources/MetronomeCore"
        ),
        .executableTarget(
            name: "MetronomeApp",
            dependencies: ["MetronomeCore"],
            path: "Sources/MetronomeApp"
        ),
        .testTarget(
            name: "MetronomeCoreTests",
            dependencies: ["MetronomeCore"],
            path: "Tests/MetronomeCoreTests",
            swiftSettings: [
                .unsafeFlags([
                    "-load-plugin-library",
                    "/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"
                ])
            ]
        )
    ]
)
