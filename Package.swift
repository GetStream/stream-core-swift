// swift-tools-version:5.9

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
    dependencies: [ ],    
    targets: [
        .target(
            name: "StreamCore",
            swiftSettings: [
                .define("BUILD_LIBRARY_FOR_DISTRIBUTION")
            ]
        )
    ]
)
