// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BiteCore",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [.library(name: "BiteCore", targets: ["BiteCore"])],
    targets: [
        .target(name: "BiteCore", path: "Bite",
                exclude: ["Views", "Components", "Assets.xcassets", "BiteApp.swift", "Utilities/Theme.swift"],
                sources: ["Models", "Engines", "Services", "Utilities/Extensions.swift", "Utilities/Haptics.swift"]),
        .testTarget(name: "BiteCoreTests", dependencies: ["BiteCore"], path: "Tests")
    ],
    swiftLanguageModes: [.v5]
)
