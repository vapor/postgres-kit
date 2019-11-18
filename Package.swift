// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "postgres-kit",
    products: [
        .library(name: "PostgresKit", targets: ["PostgresKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/postgres-nio.git", .branch("master")),
        .package(url: "https://github.com/vapor/sql-kit.git", .branch("master")),
        .package(url: "https://github.com/vapor/async-kit.git", .branch("master")),
    ],
    targets: [
        .target(name: "PostgresKit", dependencies: ["AsyncKit", "PostgresNIO", "SQLKit"]),
        .testTarget(name: "PostgresKitTests", dependencies: ["PostgresKit", "SQLKitBenchmark"]),
    ]
)
