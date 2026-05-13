// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Shikigami",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "Engines", targets: ["Engines"])
    ],
    targets: [
        .target(name: "Engines", path: "Sources/Engines"),
        .testTarget(
            name: "EnginesTests",
            dependencies: ["Engines"],
            path: "Tests/EnginesTests"
        )
    ]
)
