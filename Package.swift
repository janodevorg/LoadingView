// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LoadingView",
    platforms: [
        .iOS("26.0"),
        .macOS("26.0")
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
