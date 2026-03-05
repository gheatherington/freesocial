// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenTimeEngine",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(
            name: "ScreenTimeEngine",
            targets: ["ScreenTimeEngine"]
        ),
    ],
    dependencies: [
        .package(path: "../PolicyStore"),
    ],
    targets: [
        .target(
            name: "ScreenTimeEngine",
            dependencies: [
                .product(name: "PolicyStore", package: "PolicyStore"),
            ]
        ),
        .testTarget(
            name: "ScreenTimeEngineTests",
            dependencies: ["ScreenTimeEngine"]
        ),
    ]
)
