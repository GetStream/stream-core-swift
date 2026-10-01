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
            name: "StreamLogsUI",
            targets: ["StreamLogsUI"]
        )
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
        // Debugging tools. No dependencies, so that apps embedding StreamCore in a framework don't duplicate it.
        .target(
            name: "StreamLogsUI"
        ),
        .testTarget(
            name: "StreamLogsUITests",
            dependencies: ["StreamLogsUI", "StreamCore"]
        )
    ]
)
