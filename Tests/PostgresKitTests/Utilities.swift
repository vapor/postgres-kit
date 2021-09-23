import XCTest
import PostgresKit
import NIOCore
import Logging
#if canImport(Darwin)
import Darwin.C
#else
import Glibc
#endif

extension PostgresConnection {
    static func test(on eventLoop: EventLoop) -> EventLoopFuture<PostgresConnection> {
        do {
            let config = PostgresConfiguration.test
            let address = try config.address()
            return self.connect(to: address, on: eventLoop).flatMap { conn in
                return conn.authenticate(
                    username: config.username,
                    database: config.database,
                    password: config.password
                )
                .map { conn }
                .flatMapError { error in
                    conn.close().flatMapThrowing {
                        throw error
                    }
                }
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}

extension PostgresConfiguration {
    static var test: Self {
        .init(
            hostname: env("POSTGRES_HOSTNAME") ?? "localhost",
            port: Self.ianaPortNumber,
            username: env("POSTGRES_USER") ?? "vapor_username",
            password: env("POSTGRES_PASSWORD") ?? "vapor_password",
            database: env("POSTGRES_DB") ?? "vapor_database"
        )
    }
}

func env(_ name: String) -> String? {
    getenv(name).flatMap { String(cString: $0) }
}
