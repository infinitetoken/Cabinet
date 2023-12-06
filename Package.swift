// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cabinet",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "Cabinet",
            targets: ["Cabinet"])
    ],
    targets: [
        .target(
            name: "Cabinet",
            dependencies: ["Lumber"],
            path: "Sources"),
        .testTarget(
            name: "CabinetTests",
            dependencies: ["Cabinet"],
            path: "Tests"),
    ]
)
