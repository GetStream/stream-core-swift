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
        ),
        // Features
        .library(
            name: "StreamAttachments",
            targets: ["StreamAttachments"]
        ),
        // Debugging tools, meant for demo apps and debug builds only
        .library(
            name: "StreamCoreLogsUI",
            targets: ["StreamCoreLogsUI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/GetStream/stream-logs-ui-swift.git", revision: "dae2f9085042b7c668f718e2ffc6136b74ec177c")
    ],
    targets: [
        .target(
            name: "StreamCore"
        ),
        .testTarget(
            name: "StreamCoreTests",
            dependencies: ["StreamCore"]
        ),
        .target(
            name: "StreamCoreUI",
            dependencies: ["StreamCore"]
        ),
        .testTarget(
            name: "StreamCoreUITests",
            dependencies: ["StreamCoreUI"]
        ),
        // Features
        .target(
            name: "StreamAttachments",
            dependencies: ["StreamCore"]
        ),
        .testTarget(
            name: "StreamAttachmentsTests",
            dependencies: ["StreamAttachments"]
        ),
        // Debugging tools
        .target(
            name: "StreamCoreLogsUI",
            dependencies: [
                "StreamCore",
                .product(name: "StreamLogsUI", package: "stream-logs-ui-swift")
            ]
        ),
        .testTarget(
            name: "StreamCoreLogsUITests",
            dependencies: ["StreamCoreLogsUI"]
        )
    ]
)
