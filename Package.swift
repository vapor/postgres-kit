// swift-tools-version:5.8
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
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.21.1"),
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.29.3"),
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.19.0"),
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
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
] }
