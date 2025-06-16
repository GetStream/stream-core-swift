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
        )
    ],
    targets: [
        .target(
            name: "StreamCore",
            swiftSettings: [
                .unsafeFlags(["-enable-library-evolution"])
            ]
        ),
        .testTarget(
            name: "StreamCoreTests",
            dependencies: ["StreamCore"]
        )
    ]
)
