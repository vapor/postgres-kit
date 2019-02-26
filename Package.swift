// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "postgres-kit",
    products: [
        .library(name: "PostgresKit", targets: ["PostgresKit"]),
        .executable(name: "PostgresKitPerformance", targets: ["PostgresKitPerformance"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/nio-postgres.git", .branch("master")),
        .package(url: "https://github.com/vapor/sql.git", .branch("master")),
        .package(url: "https://github.com/vapor/nio-kit.git", .branch("master")),
    ],
    targets: [
        .target(name: "PostgresKit", dependencies: ["NIOKit", "NIOPostgres", "SQLKit"]),
        .testTarget(name: "PostgresKitTests", dependencies: ["PostgresKit", "SQLKitBenchmark"]),
        .target(name: "PostgresKitPerformance", dependencies: ["PostgresKit"]),
    ]
)
