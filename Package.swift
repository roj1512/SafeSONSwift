// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


let package = Package(
    name: "SS",
    products: [
        .library(name: "SafeSON", targets: ["SafeSON"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SafeSON",
            dependencies: []),
        .testTarget(
            name: "SafeSONTests",
            dependencies: ["SafeSON"]),
        .executableTarget(
            name: "HelloWorld",
            dependencies: ["SafeSON"]),
    ]
)
