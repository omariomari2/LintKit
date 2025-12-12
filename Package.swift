// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwiftLoc",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "swiftloc", targets: ["SwiftLoc"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/CoreOffice/XMLCoder.git", from: "0.17.0")
    ],
    targets: [
        .executableTarget(
            name: "SwiftLoc",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "XMLCoder", package: "XMLCoder")
            ]
        ),
        .testTarget(
            name: "SwiftLocTests",
            dependencies: ["SwiftLoc"]
        )
    ]
)

