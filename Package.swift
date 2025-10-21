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
        )
    ]
)
