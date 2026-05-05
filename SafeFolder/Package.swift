// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SafeFolder",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SafeFolder",
            targets: ["SafeFolder"]
        )
    ],
    targets: [
        .target(
            name: "SafeFolder",
            path: "SafeFolder",
            resources: [
                .process("Resources"),
                .process("Info.plist")
            ]
        )
    ]
)
