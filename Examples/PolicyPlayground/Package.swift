// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PolicyPlayground",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../..")],
    targets: [
        .executableTarget(
            name: "PolicyPlaygroundApp",
            dependencies: [.product(name: "KLShareLink", package: "KLShareLink")]
        ),
    ]
)
