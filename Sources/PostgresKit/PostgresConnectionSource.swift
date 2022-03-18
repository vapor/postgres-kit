import NIOConcurrencyHelpers
import NIOSSL

public struct PostgresConnectionSource: ConnectionPoolSource {
    public let configuration: PostgresConfiguration
    public let sslContext: Result<NIOSSLContext?, Error>
    private static let idGenerator = NIOAtomic.makeAtomic(value: 0)

    public init(configuration: PostgresConfiguration) {
        self.configuration = configuration
        // TODO: Figure out a way to throw errors from this initializer sensibly, or to lazily init the NIOSSLContext only once in makeConnection()
        self.sslContext = .init(catching: { try configuration._hostname.flatMap { _ in try configuration.tlsConfiguration.map { try .init(configuration: $0) } } })
    }

    public func makeConnection(
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<PostgresConnection> {
        if let hostname = self.configuration._hostname {
            let tlsMode: PostgresConnection.Configuration.TLS
            switch self.sslContext {
                case let .success(sslContext): tlsMode = sslContext.map { .require($0) } ?? .disable
                case let .failure(error): return eventLoop.makeFailedFuture(error)
            }
            let future = PostgresConnection.connect(
                on: eventLoop,
                configuration: .init(
                    connection: .init(host: hostname, port: self.configuration._port ?? PostgresConfiguration.ianaPortNumber),
                    authentication: .init(username: self.configuration.username, database: self.configuration.database, password: self.configuration.password),
                    tls: tlsMode
                ),
                id: Self.idGenerator.add(1),
                logger: logger
            )
            
            if let searchPath = self.configuration.searchPath {
                return future.flatMap { conn in
                    let string = searchPath.map { #""\#($0)""# }.joined(separator: ", ")
                    return conn.simpleQuery("SET search_path = \(string)").map { _ in conn }
                }
            } else {
                return future
            }
        } else {
            let address: SocketAddress
            do {
                address = try self.configuration.address()
            } catch {
                return eventLoop.makeFailedFuture(error)
            }

            // Legacy code path until PostgresNIO regains support for connecting directly to a SocketAddress.
            return PostgresConnection.connect(
                to: address,
                tlsConfiguration: self.configuration.tlsConfiguration,
                serverHostname: self.configuration._hostname,
                logger: logger,
                on: eventLoop
            ).flatMap { conn in
                return conn.authenticate(
                    username: self.configuration.username,
                    database: self.configuration.database,
                    password: self.configuration.password,
                    logger: logger
                ).flatMap {
                    if let searchPath = self.configuration.searchPath {
                        let string = searchPath.map { "\"" + $0 + "\"" }.joined(separator: ", ")
                        return conn.simpleQuery("SET search_path = \(string)").map { _ in conn }
                    } else {
                        return eventLoop.makeSucceededFuture(conn)
                    }
                }.flatMapErrorThrowing { error in
                    _ = conn.close()
                    throw error
                }
            }
        }
    }
}

extension PostgresConnection: ConnectionPoolItem { }
