extension PostgreSQLConnection {
    /// Connects to PostgreSQL server via TCP.
    public static func connect(
        hostname: String = "localhost",
        port: Int = 5432,
        transport: TransportConfig = .cleartext,
        on worker: Worker
    ) throws -> Future<PostgreSQLConnection> {
        return try connect(to: .tcp(hostname: hostname, port: port), transport: transport, on: worker)
    }
    
    /// Connects to PostgreSQL server specified by a `ServerAddress`.
    public static func connect(
        to serverAddress: ServerAddress,
        transport: TransportConfig = .cleartext,
        on worker: Worker
    ) throws -> Future<PostgreSQLConnection> {
        let handler = QueueHandler<PostgreSQLMessage, PostgreSQLMessage>(on: worker) { error in
            ERROR(error.localizedDescription)
        }
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
                return connection.addSSLClientHandler(using: tlsConfig, forHost: serverAddress.hostname).transform(to: connection)
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
