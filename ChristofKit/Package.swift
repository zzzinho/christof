// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ChristofKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "ChristofKit", targets: ["ChristofKit"]),
    ],
    targets: [
        .target(name: "ChristofKit"),
        .executableTarget(name: "ChristofSnapshots", dependencies: ["ChristofKit"]),
        .executableTarget(name: "ChristofAssets", dependencies: ["ChristofKit"]),
        .testTarget(name: "ChristofKitTests", dependencies: ["ChristofKit"]),
    ]
)
