import NIOSSL
import Atomics
import AsyncKit
import Logging
import PostgresNIO
import NIOCore

public struct PostgresConnectionSource: ConnectionPoolSource {
    public let configuration: PostgresConfiguration
    public let sslContext: Result<NIOSSLContext?, Error>
    private static let idGenerator = ManagedAtomic<Int>(0)

    public init(configuration: PostgresConfiguration) {
        self.configuration = configuration
        // TODO: Figure out a way to throw errors from this initializer sensibly, or to lazily init the NIOSSLContext only once in makeConnection()
        self.sslContext = .init(catching: { try configuration._hostname.flatMap { _ in try configuration.tlsConfiguration.map { try .init(configuration: $0) } } })
    }

    public func makeConnection(
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<PostgresConnection> {
        let tlsMode: PostgresConnection.Configuration.TLS
        switch self.sslContext {
            case let .success(sslContext): tlsMode = sslContext.map { .require($0) } ?? .disable
            case let .failure(error): return eventLoop.makeFailedFuture(error)
        }
        
        let connectionFuture: EventLoopFuture<PostgresConnection>
        
        if let hostname = self.configuration._hostname {
            var config = PostgresConnection.Configuration(
                host: hostname,
                username: self.configuration.username, password: self.configuration.password, database: self.configuration.database,
                tls: tlsMode
            )
            config.options.requireBackendKeyData = configuration.requireBackendKeyData
            
            connectionFuture = PostgresConnection.connect(
                on: eventLoop,
                configuration: config,
                id: Self.idGenerator.wrappingIncrementThenLoad(ordering: .relaxed),
                logger: logger
            )
        } else {
            let address: SocketAddress
            do {
                address = try self.configuration.address()
            } catch {
                return eventLoop.makeFailedFuture(error)
            }

            connectionFuture = ClientBootstrap(group: eventLoop).connect(to: address)
                .flatMap { channel in
                    var config = PostgresConnection.Configuration(
                        establishedChannel: channel,
                        username: self.configuration.username, password: self.configuration.password,
                        database: self.configuration.database
                    )
                    config.tls = tlsMode
                    config.options.tlsServerName = self.configuration._hostname
                    return PostgresConnection.connect(
                        on: eventLoop,
                        configuration: config,
                        id: Self.idGenerator.wrappingIncrementThenLoad(ordering: .relaxed),
                        logger: logger
                    )
                }
        }
        
        if let searchPath = self.configuration.searchPath {
            return connectionFuture.flatMap { conn in
                let string = searchPath.map { #""\#($0)""# }.joined(separator: ", ")
                return conn.simpleQuery("SET search_path = \(string)").map { _ in conn }
            }
        } else {
            return connectionFuture
        }
    }
}

extension PostgresConnection: ConnectionPoolItem { }
