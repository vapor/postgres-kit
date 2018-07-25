import Foundation
import NIOOpenSSL

/// Config options for a `PostgreSQLConnection`
public struct PostgreSQLDatabaseConfig {
    /// Creates a `PostgreSQLDatabaseConfig` with default settings.
    public static func `default`() throws -> PostgreSQLDatabaseConfig {
        return .init(hostname: "localhost", port: 5432, username: "postgres")
    }

    /// Username to authenticate.
    public let username: String
    
    /// Optional database name to use during authentication.
    /// Defaults to the username.
    public let database: String?
    
    /// Optional password to use for authentication.
    public let password: String?
    
    /// Which server to connect to.
    public let serverAddress: PostgreSQLConnection.ServerAddress
    
    /// Configures how data is transported to the server. Use this to enable SSL.
    /// See `PostgreSQLTransportConfig` for more info
    public let transportConfig: PostgreSQLConnection.TransportConfig
    
    /// Creates a new `PostgreSQLDatabaseConfig`.
    public init(hostname: String, port: Int = 5432, username: String, database: String? = nil, password: String? = nil, transport: PostgreSQLConnection.TransportConfig = .cleartext) {
        self.init(serverAddress: .tcp(hostname: hostname, port: port), username: username, database: database, password: password, transport: transport)
    }

    /// Creates a new `PostgreSQLDatabaseConfig`.
    public init(serverAddress: PostgreSQLConnection.ServerAddress, username: String, database: String? = nil, password: String? = nil, transport: PostgreSQLConnection.TransportConfig = .cleartext) {
        self.username = username
        self.database = database
        self.password = password
        self.serverAddress = serverAddress
        self.transportConfig = transport
    }

    /// Creates a new `PostgreSQLDatabaseConfig`.
    public init?(url urlString: String, transport: PostgreSQLConnection.TransportConfig = .cleartext) {
        guard let url = URL(string: urlString) else {
            return nil
        }
        self.init(
            hostname: url.host ?? "localhost",
            port: url.port ?? 5432,
            username: url.user ?? "vapor",
            database: url.databaseName,
            password: url.password,
            transport: transport
        )
    }
}
