// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LinkInspector",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../..")],
    targets: [
        .executableTarget(
            name: "LinkInspectorApp",
            dependencies: [.product(name: "KLShareLink", package: "KLShareLink")]
        ),
    ]
)
