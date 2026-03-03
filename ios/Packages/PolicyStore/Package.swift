// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PolicyStore",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "PolicyStore",
            targets: ["PolicyStore"]
        ),
    ],
    targets: [
        .target(
            name: "PolicyStore",
            dependencies: []
        ),
        .testTarget(
            name: "PolicyStoreTests",
            dependencies: ["PolicyStore"]
        ),
    ]
)
