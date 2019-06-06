public struct PostgresConnectionSource: ConnectionPoolSource {
    public var eventLoop: EventLoop
    public let configuration: PostgresConfiguration

    public init(configuration: PostgresConfiguration, on eventLoop: EventLoop) {
        self.configuration = configuration
        self.eventLoop = eventLoop
    }

    public func makeConnection() -> EventLoopFuture<PostgresConnection> {
        let address: SocketAddress
        do {
            address = try self.configuration.address()
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
        return PostgresConnection.connect(
            to: address,
            tlsConfiguration: self.configuration.tlsConfiguration,
            on: self.eventLoop
        ).flatMap { conn in
            return conn.authenticate(
                username: self.configuration.username,
                database: self.configuration.database,
                password: self.configuration.password
            ).map { conn }
        }
    }
}

extension PostgresConnection: ConnectionPoolItem { }
