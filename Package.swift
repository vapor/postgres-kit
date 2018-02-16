// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "PostgreSQL",
    products: [
        .library(name: "PostgreSQL", targets: ["PostgreSQL"]),
    ],
    dependencies: [
        // Swift Promises, Futures, and Streams.
        .package(url: "https://github.com/vapor/async.git", "1.0.0-beta.1"..<"1.0.0-beta.2"),
        
        // Core extensions, type-aliases, and functions that facilitate common tasks.
        .package(url: "https://github.com/vapor/core.git", "3.0.0-beta.1"..<"3.0.0-beta.2"),
        
        // Cryptography modules (formerly CryptoKitten)
        .package(url: "https://github.com/vapor/crypto.git", "3.0.0-beta.1"..<"3.0.0-beta.2"),

        // Core services for creating database integrations.
        .package(url: "https://github.com/vapor/database-kit.git", "1.0.0-beta.3"..<"1.0.0-beta.4"),

        // Non-blocking networking for Swift (HTTP and WebSockets).
        .package(url: "https://github.com/vapor/engine.git", "3.0.0-beta.2"..<"3.0.0-beta.3"),

        // Service container and configuration system.
        .package(url: "https://github.com/vapor/service.git", "1.0.0-beta.1"..<"1.0.0-beta.2"),

        // Pure Swift (POSIX) TCP and UDP non-blocking socket layer, with event-driven Server and Client.
        .package(url: "https://github.com/vapor/sockets.git", "3.0.0-beta.2"..<"3.0.0-beta.3"),
    ],
    targets: [
        .target(name: "PostgreSQL", dependencies: ["Async", "Bits", "Crypto", "DatabaseKit", "Service", "TCP"]),
        .testTarget(name: "PostgreSQLTests", dependencies: ["PostgreSQL"]),
    ]
)
