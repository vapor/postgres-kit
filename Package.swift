// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "PostgreSQL",
    products: [
        .library(name: "PostgreSQL", targets: ["PostgreSQL"]),
    ],
    dependencies: [
        // Swift Promises, Futures, and Streams.
        .package(url: "https://github.com/vapor/async.git", .branch("beta")),
        
        // Core extensions, type-aliases, and functions that facilitate common tasks.
        .package(url: "https://github.com/vapor/core.git", .branch("beta")),

        // Core services for creating database integrations.
        .package(url: "https://github.com/vapor/database-kit.git", .branch("beta")),

        // Non-blocking networking for Swift (HTTP and WebSockets).
        .package(url: "https://github.com/vapor/engine.git", .branch("beta")),

        // Service container and configuration system.
        .package(url: "https://github.com/vapor/service.git", .branch("beta")),

        // Pure Swift (POSIX) TCP and UDP non-blocking socket layer, with event-driven Server and Client.
        .package(url: "https://github.com/vapor/sockets.git", .branch("beta")),
    ],
    targets: [
        .target(name: "PostgreSQL", dependencies: ["Async", "Bits", "DatabaseKit", "Service", "TCP"]),
        .testTarget(name: "PostgreSQLTests", dependencies: ["PostgreSQL"]),
    ]
)
