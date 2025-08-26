// swift-tools-version:5.10
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
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.27.0"),
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.33.1"),
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.21.0"),
    ],
    targets: [
        .target(
            name: "PostgresKit",
            dependencies: [
                .product(name: "AsyncKit", package: "async-kit"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "SQLKit", package: "sql-kit"),
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
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableExperimentalFeature("StrictConcurrency=complete"),
] }
