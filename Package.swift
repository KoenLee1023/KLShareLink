// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "KLShareLink",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "KLShareLink", targets: ["KLShareLink"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-docc-plugin",
            from: "1.4.0"
        ),
    ],
    targets: [
        .target(name: "KLShareLink"),
        .testTarget(name: "KLShareLinkTests", dependencies: ["KLShareLink"]),
    ]
)
