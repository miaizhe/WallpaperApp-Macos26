// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DynamicWallpaperApp",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "DynamicWallpaperApp",
            targets: ["DynamicWallpaperApp"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DynamicWallpaperApp",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
