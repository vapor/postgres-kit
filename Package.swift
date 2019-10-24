// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "postgres-kit",
    products: [
        .library(name: "PostgresKit", targets: ["PostgresKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.0.0-alpha"),
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.0.0-beta"),
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.0.0-beta"),
    ],
    targets: [
        .target(name: "PostgresKit", dependencies: ["AsyncKit", "PostgresNIO", "SQLKit"]),
        .testTarget(name: "PostgresKitTests", dependencies: ["PostgresKit", "SQLKitBenchmark"]),
    ]
)
