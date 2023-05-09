import XCTest
import PostgresKit
import Logging
import Foundation
import NIOCore
import PostgresNIO

extension PostgresConnection {
    static func test(on eventLoop: any EventLoop) -> EventLoopFuture<PostgresConnection> {
        PostgresConnectionSource(sqlConfiguration: .test).makeConnection(logger: .init(label: "vapor.codes.postgres-kit.test"), on: eventLoop)
    }
}

extension SQLPostgresConfiguration {
    static var test: Self {
        .init(
            hostname: env("POSTGRES_HOSTNAME") ?? "localhost",
            port: env("POSTGRES_PORT").flatMap(Int.init) ?? Self.ianaPortNumber,
            username: env("POSTGRES_USER") ?? "vapor_username",
            password: env("POSTGRES_PASSWORD") ?? "vapor_password",
            database: env("POSTGRES_DB") ?? "vapor_database",
            tls: .disable
        )
    }
}

func env(_ name: String) -> String? {
    ProcessInfo.processInfo.environment[name]
}
