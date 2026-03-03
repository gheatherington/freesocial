// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenTimeEngine",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "ScreenTimeEngine",
            targets: ["ScreenTimeEngine"]
        ),
    ],
    targets: [
        .target(
            name: "ScreenTimeEngine",
            dependencies: []
        ),
        .testTarget(
            name: "ScreenTimeEngineTests",
            dependencies: ["ScreenTimeEngine"]
        ),
    ]
)
