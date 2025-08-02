// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "LoadingView",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "LoadingView",
            targets: ["LoadingView"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "LoadingView",
            dependencies: [
            ],
            path: "Sources/Main"
        ),
        .testTarget(
            name: "LoadingViewTests",
            dependencies: ["LoadingView"],
            path: "Sources/Tests"
        )
    ]
)
