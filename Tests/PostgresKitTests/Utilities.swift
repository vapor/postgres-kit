import XCTest
import PostgresKit
import Logging
#if canImport(Darwin)
import Darwin.C
#else
import Glibc
#endif

extension PostgresConnection {
    static func test(on eventLoop: EventLoop) -> EventLoopFuture<PostgresConnection> {
        return PostgresConnectionSource(configuration: .test).makeConnection(logger: .init(label: "vapor.codes.postgres-kit.test"), on: eventLoop)
    }
}

extension PostgresConfiguration {
    static var test: Self {
        .init(
            hostname: env("POSTGRES_HOSTNAME") ?? "localhost",
            port: env("POSTGRES_PORT").flatMap(Int.init) ?? Self.ianaPortNumber,
            username: env("POSTGRES_USER") ?? "vapor_username",
            password: env("POSTGRES_PASSWORD") ?? "vapor_password",
            database: env("POSTGRES_DB") ?? "vapor_database",
            tlsConfiguration: nil
        )
    }
}

func env(_ name: String) -> String? {
    getenv(name).flatMap { String(cString: $0) }
}
