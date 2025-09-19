// swift-tools-version:6.0

import Foundation
import PackageDescription

let package = Package(
    name: "StreamCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "StreamCore",
            targets: ["StreamCore"]
        ),
        .library(
            name: "StreamCoreUI",
            targets: ["StreamCoreUI"]
        )
    ],
    targets: [
        .target(
            name: "StreamCore",
            swiftSettings: [
                .unsafeFlags(["-enable-library-evolution"])
            ]
        ),
        .target(
            name: "StreamCoreUI",
            dependencies: ["StreamCore"],
            swiftSettings: [
                .unsafeFlags(["-enable-library-evolution"])
            ]
        ),
        .testTarget(
            name: "StreamCoreTests",
            dependencies: ["StreamCore"]
        ),
        .testTarget(
            name: "StreamCoreUITests",
            dependencies: ["StreamCoreUI"]
        )
    ]
)
