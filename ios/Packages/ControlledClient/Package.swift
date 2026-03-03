// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ControlledClient",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "ControlledClient",
            targets: ["ControlledClient"]
        ),
    ],
    dependencies: [
        .package(path: "../PolicyStore"),
    ],
    targets: [
        .target(
            name: "ControlledClient",
            dependencies: ["PolicyStore"]
        ),
        .testTarget(
            name: "ControlledClientTests",
            dependencies: ["ControlledClient"]
        ),
    ]
)
