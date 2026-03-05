// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ConsentManager",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(
            name: "ConsentManager",
            targets: ["ConsentManager"]
        ),
    ],
    targets: [
        .target(
            name: "ConsentManager",
            dependencies: []
        ),
        .testTarget(
            name: "ConsentManagerTests",
            dependencies: ["ConsentManager"]
        ),
    ]
)
