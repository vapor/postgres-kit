extension PostgreSQLConnection {
    /// Specifies how to connect to a PostgreSQL server.
    public struct ServerAddress {
        public static var `default`: ServerAddress {
            return .tcp(hostname: "localhost", port: 5432)
        }
        
        public static var socketDefault: ServerAddress {
            return .unixSocket(path: "/tmp/.s.PGSQL.5432")
        }
        
        public static func tcp(hostname: String, port: Int) -> ServerAddress {
            return .init(.tcp(hostname: hostname, port: port))
        }
        
        public static func unixSocket(path: String) -> ServerAddress {
            return .init(.unixSocket(path: path))
        }
        
        public static func socketAddress(_ socketAddress: SocketAddress) -> ServerAddress {
            return .init(.socketAddress(socketAddress))
        }
        
        /// Internal storage type.
        enum Storage {
            /// Connect via TCP using the given hostname and port.
            case tcp(hostname: String, port: Int)
            /// Connect via a Unix domain socket file.
            case unixSocket(path: String)
            /// A raw NIO socket address.
            case socketAddress(SocketAddress)
        }
        
        /// Internal storage.
        let storage: Storage
        
        init(_ storage: Storage) {
            self.storage = storage
        }
    }
}
