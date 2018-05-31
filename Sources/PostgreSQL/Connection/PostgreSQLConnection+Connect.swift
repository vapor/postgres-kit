extension PostgreSQLConnection {
    public static func connect(
        hostname: String = "localhost",
        port: Int = 5432,
        transport: TransportConfig = .cleartext,
        on worker: Worker,
        onError: @escaping (Error) -> ()
    ) throws -> Future<PostgreSQLConnection> {
        return try connect(to: .tcp(hostname: hostname, port: port), transport: transport, on: worker, onError: onError)
    }
    
    public static func connect(
        to serverAddress: ServerAddress,
        transport: TransportConfig = .cleartext,
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
        return bootstrap.connect(to: serverAddress).flatMap { channel in
            let connection = PostgreSQLConnection(queue: handler, channel: channel)
            switch transport.storage {
            case .cleartext:
                return worker.future(connection)
            case .tls(let tlsConfig):
                return connection.addSSLClientHandler(using: tlsConfig).transform(to: connection)
            }
        }
    }
}

private extension ClientBootstrap {
    /// PostgreSQL specific address connect.
    func connect(to serverAddress: PostgreSQLConnection.ServerAddress) -> Future<Channel> {
        switch serverAddress.storage {
        case .socketAddress(let socketAddress): return connect(to: socketAddress)
        case .tcp(let hostname, let port): return connect(host: hostname, port: port)
        case .unixSocket(let path): return connect(unixDomainSocketPath: path)
        }
    }
}
