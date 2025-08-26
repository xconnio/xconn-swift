// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XConn",
    platforms: [
        .macOS(.v10_15), // Requires macOS 10.15 or newer
        .iOS(.v13), // Requires iOS 13 or newer
        .tvOS(.v13), // Requires tvOS 13 or newer
        .watchOS(.v6) // Requires watchOS 6 or newer,
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "XConn", targets: ["XConn"])
        // .executable(name: "Running", targets: ["Running"])
    ],
    dependencies: [
        // .package(name: "Wampproto", path: "../wampproto-swift")
        .package(url: "https://github.com/xconnio/wampproto-swift.git", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "XConn",
            dependencies: [
                // "Wampproto"
                .product(name: "Wampproto", package: "wampproto-swift")
            ]
        ),
        // .executableTarget(name: "Running", dependencies: ["XConn"]),
        .testTarget(
            name: "XConnTests",
            dependencies: ["XConn"]
        )
    ]
)
