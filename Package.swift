// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "PostgreSQL",
    products: [
        .library(name: "PostgreSQL", targets: ["PostgreSQL"]),
    ],
    dependencies: [
        // Swift Promises, Futures, and Streams.
        .package(url: "https://github.com/vapor/async.git", .exact("1.0.0-beta.1")),
        
        // Core extensions, type-aliases, and functions that facilitate common tasks.
        .package(url: "https://github.com/vapor/core.git", .exact("3.0.0-beta.1")),
        
        // Cryptography modules (formerly CryptoKitten)
        .package(url: "https://github.com/vapor/crypto.git", .exact("3.0.0-beta.1")),

        // Core services for creating database integrations.
        .package(url: "https://github.com/vapor/database-kit.git", .exact("1.0.0-beta.2")),

        // Non-blocking networking for Swift (HTTP and WebSockets).
        .package(url: "https://github.com/vapor/engine.git", .exact("3.0.0-beta.2")),

        // Service container and configuration system.
        .package(url: "https://github.com/vapor/service.git", .exact("1.0.0-beta.1")),

        // Pure Swift (POSIX) TCP and UDP non-blocking socket layer, with event-driven Server and Client.
        .package(url: "https://github.com/vapor/sockets.git", .exact("3.0.0-beta.2")),
    ],
    targets: [
        .target(name: "PostgreSQL", dependencies: ["Async", "Bits", "Crypto", "DatabaseKit", "Service", "TCP"]),
        .testTarget(name: "PostgreSQLTests", dependencies: ["PostgreSQL"]),
    ]
)
