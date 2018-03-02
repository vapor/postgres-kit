import Async
import NIO

extension PostgreSQLConnection {
    /// Connects to a Redis server using a TCP socket.
    public static func connect(
        hostname: String = "localhost",
        port: UInt16 = 5432,
        on worker: Worker,
        onError: @escaping (Error) -> ()
    ) throws -> PostgreSQLConnection {
        let handler = HTTPClientHandler()
        let bootstrap = ClientBootstrap(group: group)
            // Enable SO_REUSEADDR.
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                return channel.pipeline.addHTTPClientHandlers().then {
                    channel.pipeline.add(handler: handler)
                }
        }

        return bootstrap.connect(host: hostname, port: port).map(to: HTTPClient.self) { _ in
            return .init(handler: handler, bootstrap: bootstrap)
        }
        return PostgreSQLConnection(stream: stream, on: worker)
    }
}
