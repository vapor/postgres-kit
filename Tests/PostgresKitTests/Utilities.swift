import PostgresKit

extension PostgresConnection {
    static func test(on eventLoop: EventLoop) -> EventLoopFuture<PostgresConnection> {
        do {
            let address: SocketAddress
            address = try .makeAddressResolvingHost(hostname, port: 5432)
            return connect(to: address, on: eventLoop).flatMap { conn in
                return conn.authenticate(
                    username: "vapor_username",
                    database: "vapor_database",
                    password: "vapor_password"
                ).map { conn }
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
            port: 5432,
            username: "vapor_username",
            password: "vapor_password",
            database: "vapor_database"
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
