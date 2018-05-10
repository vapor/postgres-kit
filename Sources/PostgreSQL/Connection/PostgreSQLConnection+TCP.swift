import Async
import NIO
import NIOOpenSSL

extension PostgreSQLConnection {
    /// Connects to a Redis server using a TCP socket.
    public static func connect(
        hostname: String = "localhost",
        port: Int = 5432,
        transportConfig: PostgreSQLTransportConfig = .cleartext,
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

        return bootstrap.connect(host: hostname, port: port).flatMap(to: PostgreSQLConnection.self) { channel in
            let connection = PostgreSQLConnection(queue: handler, channel: channel)
            if case .tls(let tlsConfiguration) = transportConfig.method {
                return connection.addSSLClientHandler(using: tlsConfiguration).transform(to: connection)
            }
            return worker.eventLoop.newSucceededFuture(result: connection)
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
