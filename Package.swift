// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Appfiliate",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Appfiliate",
            targets: ["Appfiliate"]
        ),
    ],
    targets: [
        .target(
            name: "Appfiliate",
            path: "Sources/Appfiliate"
        ),
    ]
)
