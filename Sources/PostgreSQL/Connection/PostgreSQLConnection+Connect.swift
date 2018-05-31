import Async
import NIO
import NIOOpenSSL

extension PostgreSQLConnection {
    @available(*, deprecated, message: "Use `.connect(to:...)` instead.")
    public static func connect(
        hostname: String = "localhost",
        port: Int = 5432,
        transport: PostgreSQLTransportConfig = .cleartext,
        on worker: Worker,
        onError: @escaping (Error) -> ()
        ) throws -> Future<PostgreSQLConnection> {
        return try connect(to: .tcp(hostname: hostname, port: port), transport: transport, on: worker, onError: onError)
    }
    
    /// Connects to a PostgreSQL server using a TCP socket.
    public static func connect(
        to serverAddress: PostgreSQLDatabaseConfig.ServerAddress = .default,
        transport: PostgreSQLTransportConfig = .cleartext,
        on worker: Worker,
        onError: @escaping (Error) -> ()
        ) throws -> Future<PostgreSQLConnection> {
        let handler = QueueHandler<PostgreSQLMessage, PostgreSQLMessage>(on: worker, onError: onError)
        let bootstrap = ClientBootstrap(group: worker.eventLoop)
            // Enable SO_REUSEADDR.
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                return channel.pipeline.addPostgreSQLClientHandlers().then {
                    channel.pipeline.add(handler: handler)
                }
        }
        
        let connectedBootstrap: Future<Channel>
        switch serverAddress {
        case let .tcp(hostname, port):
            connectedBootstrap = bootstrap.connect(host: hostname, port: port)
        case let .unixSocket(socketPath):
            connectedBootstrap = bootstrap.connect(unixDomainSocketPath: socketPath)
        }
        
        return connectedBootstrap.flatMap { channel in
            let connection = PostgreSQLConnection(queue: handler, channel: channel)
            if case .tls(let tlsConfiguration) = transport.method {
                return connection.addSSLClientHandler(using: tlsConfiguration).transform(to: connection)
            } else {
                return worker.eventLoop.newSucceededFuture(result: connection)
            }
        }
    }
}

extension ChannelPipeline {
    func addPostgreSQLClientHandlers(first: Bool = false) -> EventLoopFuture<Void> {
        return addHandlers(PostgreSQLMessageEncoder(), PostgreSQLMessageDecoder(), first: first)
    }

    /// Adds the provided channel handlers to the pipeline in the order given, taking account
    /// of the behaviour of `ChannelHandler.add(first:)`.
    private func addHandlers(_ handlers: ChannelHandler..., first: Bool) -> EventLoopFuture<Void> {
        var handlers = handlers
        if first {
            handlers = handlers.reversed()
        }

        return EventLoopFuture<Void>.andAll(handlers.map { add(handler: $0) }, eventLoop: eventLoop)
    }
}
