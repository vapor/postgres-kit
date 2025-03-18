import Foundation
import Logging
import NIOCore
import PostgresKit
import PostgresNIO
import XCTest

extension PostgresConnection {
    static func test(on eventLoop: any EventLoop) -> EventLoopFuture<PostgresConnection> {
        PostgresConnectionSource(sqlConfiguration: .test).makeConnection(
            logger: .init(label: "vapor.codes.postgres-kit.test"),
            on: eventLoop
        )
    }
}

extension SQLPostgresConfiguration {
    static var test: Self {
        .init(
            hostname: env("POSTGRES_HOSTNAME") ?? "localhost",
            port: env("POSTGRES_PORT").flatMap(Int.init) ?? Self.ianaPortNumber,
            username: env("POSTGRES_USER") ?? "test_username",
            password: env("POSTGRES_PASSWORD") ?? "test_password",
            database: env("POSTGRES_DB") ?? "test_database",
            tls: .disable
        )
    }
}

func env(_ name: String) -> String? {
    ProcessInfo.processInfo.environment[name]
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = env("LOG_LEVEL").flatMap { .init(rawValue: $0) } ?? .info
        return handler
    }
    return true
}()
