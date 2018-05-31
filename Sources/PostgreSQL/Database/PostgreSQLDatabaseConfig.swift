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
    
    public init(hostname: String, port: Int = 5432, username: String, database: String? = nil, password: String? = nil, transport: PostgreSQLConnection.TransportConfig = .cleartext) {
        self.init(serverAddress: .tcp(hostname: hostname, port: port), username: username, database: database, password: password, transport: transport)
    }
    
	public init(serverAddress: PostgreSQLConnection.ServerAddress, username: String, database: String? = nil, password: String? = nil, transport: PostgreSQLConnection.TransportConfig = .cleartext) {
		self.username = username
		self.database = database
		self.password = password
        self.serverAddress = serverAddress
		self.transportConfig = transport
	}

    public init(url urlString: String, transport: PostgreSQLConnection.TransportConfig = .cleartext) throws {
        guard let url = URL(string: urlString),
            let hostname = url.host,
            let port = url.port,
            let username = url.user,
            let database = url.databaseName,
            url.path.count > 0
        else {
            throw PostgreSQLError(
                identifier: "Bad Connection String",
                reason: "Host could not be parsed",
                possibleCauses: ["Foundation URL is unable to parse the provided connection string"],
                suggestedFixes: ["Check the connection string being passed"]
            )
        }
        self.serverAddress = .tcp(hostname: hostname, port: port)
        self.username = username
        self.database = database
        self.password = url.password
        self.transportConfig = transport
    }
}
