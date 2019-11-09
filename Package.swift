// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "CommandLineAPI",
    products: [
        .library(name: "CommandLineAPI", targets: ["CommandLineAPI"])
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Nimble", from: "8.0.4")
    ],
    targets: [
        .target(name: "CommandLineAPI", path: "Sources"),
        .testTarget(name: "CommandLineAPITests", dependencies: ["CommandLineAPI", "Nimble"]),
    ]
)
