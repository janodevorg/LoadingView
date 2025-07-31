// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LoadingView",
    platforms: [
        .iOS("26.0"),
        .macOS("15.0")
    ],
    products: [
        .library(
            name: "LoadingView",
            targets: ["LoadingView"])
    ],
    dependencies: [
        .package(url: "git@github.com:SimplyDanny/SwiftLintPlugins.git", from: "0.58.2"),
    ],
    targets: [
        .target(
            name: "LoadingView",
            dependencies: [
            ],
            path: "Sources/Main",
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .testTarget(
            name: "LoadingViewTests",
            dependencies: ["LoadingView"],
            path: "Sources/Tests"
        )
    ]
)
