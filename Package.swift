// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "postgres-kit",
    products: [
        .library(name: "PostgresKit", targets: ["PostgresKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor-community/nio-postgres.git", .branch("master")),
        .package(url: "https://github.com/vapor/sql.git", .branch("3")),
        .package(url: "https://github.com/vapor/database-kit.git", .branch("2")),
    ],
    targets: [
        .target(name: "PostgresKit", dependencies: ["DatabaseKit", "NIOPostgres", "SQLKit"]),
        .testTarget(name: "PostgresKitTests", dependencies: ["PostgresKit", "SQLKitBenchmark"]),
    ]
)
