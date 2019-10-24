public struct PostgresConnectionSource: ConnectionPoolSource {
    public let configuration: PostgresConfiguration

    public init(configuration: PostgresConfiguration) {
        self.configuration = configuration
    }

    public func makeConnection(on eventLoop: EventLoop) -> EventLoopFuture<PostgresConnection> {
        let address: SocketAddress
        do {
            address = try self.configuration.address()
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
        return PostgresConnection.connect(
            to: address,
            tlsConfiguration: self.configuration.tlsConfiguration,
            on: eventLoop
        ).flatMap { conn in
            return conn.authenticate(
                username: self.configuration.username,
                database: self.configuration.database,
                password: self.configuration.password
            ).flatMapErrorThrowing { error in
                _ = conn.close()
                throw error
            }.map { conn }
        }
    }
}

extension PostgresConnection: ConnectionPoolItem { }
