// swift-tools-version:5.9
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "postgres-kit",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16),
    ],
    products: [
        .library(name: "PostgresKit", targets: ["PostgresKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.14.2"),
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.28.0"),
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.14.0"),
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-syntax", from: "509.0.0"),
    ],
    targets: [
        .target(name: "PostgresKit", dependencies: [
            .product(name: "AsyncKit", package: "async-kit"),
            .product(name: "PostgresNIO", package: "postgres-nio"),
            .product(name: "SQLKit", package: "sql-kit"),
            .product(name: "Atomics", package: "swift-atomics"),
            .target(name: "PostgresRecordMacro"),
        ]),
        .macro(
            name: "PostgresRecordMacro",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
            ],
            path: "./Macros/PostgresRecordMacro"
        ),
        .testTarget(name: "PostgresKitTests", dependencies: [
            .target(name: "PostgresKit"),
            .product(name: "SQLKitBenchmark", package: "sql-kit"),
        ]),
        .testTarget(
            name: "MacroTests",
            dependencies: [
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                .target(name: "PostgresRecordMacro"),
            ]
        ),
    ]
)
