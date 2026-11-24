// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HyperCapsLockApp",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "HyperCapsLockCore",
            targets: ["HyperCapsLockCore"]
        ),
        .executable(
            name: "HyperCapsLockApp",
            targets: ["HyperCapsLockApp"]
        ),
    ],
    targets: [
        .target(
            name: "HyperCapsLockCore"
        ),
        .executableTarget(
            name: "HyperCapsLockApp",
            dependencies: ["HyperCapsLockCore"]
        ),
        .testTarget(
            name: "HyperCapsLockCoreTests",
            dependencies: ["HyperCapsLockCore"]
        ),
    ]
)
