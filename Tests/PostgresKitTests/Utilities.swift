import PostgresKit

extension PostgresConnection {
    static func test(on eventLoop: EventLoop) -> EventLoopFuture<PostgresConnection> {
        do {
            let address: SocketAddress
            #if os(Linux)
            address = try .makeAddressResolvingHost("psql", port: 5432)
            #else
            address = try .init(ipAddress: "127.0.0.1", port: 5432)
            #endif
            return connect(to: address, on: eventLoop).flatMap { conn in
                return conn.authenticate(username: "vapor_username", database: "vapor_database", password: "vapor_password")
                    .map { conn }
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}

var hostname: String {
    #if os(Linux)
    return "psql"
    #else
    return "127.0.0.1"
    #endif
}
