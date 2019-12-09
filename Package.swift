// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "postgres-kit",
    platforms: [
       .macOS(.v10_14)
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
        .target(name: "PostgresKit", dependencies: ["AsyncKit", "PostgresNIO", "SQLKit"]),
        .testTarget(name: "PostgresKitTests", dependencies: ["PostgresKit", "SQLKitBenchmark"]),
    ]
)
