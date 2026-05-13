// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Shikigami",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "Engines", targets: ["Engines"]),
        .library(name: "WorldID", targets: ["WorldID"])
    ],
    targets: [
        .target(name: "Engines", path: "Sources/Engines"),
        .target(name: "WorldID", path: "Sources/WorldID"),
        .testTarget(
            name: "EnginesTests",
            dependencies: ["Engines"],
            path: "Tests/EnginesTests"
        ),
        .testTarget(
            name: "WorldIDTests",
            dependencies: ["WorldID"],
            path: "Tests/WorldIDTests"
        )
    ]
)
