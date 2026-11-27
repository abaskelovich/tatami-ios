// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TatamiCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "TatamiCore", targets: ["TatamiCore"])],
    targets: [
        .target(name: "TatamiCore"),
        .testTarget(name: "TatamiCoreTests", dependencies: ["TatamiCore"])
    ],
    swiftLanguageModes: [.v5]
)
