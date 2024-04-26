// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "postgres-kit",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(name: "PostgresKit", targets: ["PostgresKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.20.2"),
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.28.0"),
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.19.0"),
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "PostgresKit",
            dependencies: [
                .product(name: "AsyncKit", package: "async-kit"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "SQLKit", package: "sql-kit"),
                .product(name: "Atomics", package: "swift-atomics"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "PostgresKitTests",
            dependencies: [
                .target(name: "PostgresKit"),
                .product(name: "SQLKitBenchmark", package: "sql-kit"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableUpcomingFeature("StrictConcurrency"),
    .enableExperimentalFeature("StrictConcurrency=complete"),
] }
