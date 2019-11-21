// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "postgres-kit",
    products: [
        .library(name: "PostgresKit", targets: ["PostgresKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/skelpo/postgres-nio.git", from: "1.0.0-beta.1"),
        .package(url: "https://github.com/skelpo/sql-kit.git", from: "3.0.0-beta.2.1"),
        .package(url: "https://github.com/skelpo/async-kit.git", from: "1.0.0-beta.1.1"),
    ],
    targets: [
        .target(name: "PostgresKit", dependencies: ["AsyncKit", "PostgresNIO", "SQLKit"]),
        .testTarget(name: "PostgresKitTests", dependencies: ["PostgresKit", "SQLKitBenchmark"]),
    ]
)
