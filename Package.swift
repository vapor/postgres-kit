// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "postgres-kit",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "PostgresKit", targets: ["PostgresKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.0.0-beta.2"),
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.0.0-beta.2"),
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.0.0-beta.2"),
    ],
    targets: [
        .target(name: "PostgresKit", dependencies: [
            .product(name: "AsyncKit", package: "async-kit"),
            .product(name: "PostgresNIO", package: "postgres-nio"),
            .product(name: "SQLKit", package: "sql-kit"),
        ]),
        .testTarget(name: "PostgresKitTests", dependencies: [
            .target(name: "PostgresKit"),
            .product(name: "SQLKitBenchmark", package: "sql-kit"),
        ]),
    ]
)
