import PostgresKit

extension PostgresConnection {
    static func test(on eventLoop: EventLoop) -> EventLoopFuture<PostgresConnection> {
        do {
            let address: SocketAddress
            let config = PostgresConfiguration.test
            address = try config.address()
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
            hostname: hostname,
            port: Self.ianaPortNumber,
            username: env("POSTGRES_USER") ?? "vapor_username",
            password: env("POSTGRES_PASSWORD") ?? "vapor_password",
            database: env("POSTGRES_DB") ?? "vapor_database"
        )
    }
}

var hostname: String {
    if let hostname = env("POSTGRES_HOSTNAME") {
        return hostname
    } else {
        #if os(Linux)
        return "psql"
        #else
        return "127.0.0.1"
        #endif
    }
}
