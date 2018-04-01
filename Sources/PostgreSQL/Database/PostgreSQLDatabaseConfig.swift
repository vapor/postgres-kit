import Foundation
/// Config options for a `PostgreSQLConnection`
public struct PostgreSQLDatabaseConfig {
    /// Creates a `PostgreSQLDatabaseConfig` with default settings.
    public static func `default`() -> PostgreSQLDatabaseConfig {
        return .init(hostname: "localhost", port: nil, username: "postgres")
    }

    /// Destination hostname.
    public let hostname: String

    /// Destination port.
    public let port: Int

    /// Username to authenticate.
    public let username: String
    
    /// Optional database name to use during authentication.
    /// Defaults to the username.
    public let database: String?
    
    /// Optional password to use for authentication.
    public let password: String?
    
    /// Creates a new `PostgreSQLDatabaseConfig`.
    public init(hostname: String, port: Int?, username: String, database: String? = nil, password: String? = nil) {
        self.hostname = hostname
        self.port = port ?? 5432
        self.username = username
        self.database = database
        self.password = password
    }

    /// Creates a `PostgreSQLDatabaseConfig` frome a connection string.
    public init(url: String) throws {
        guard let urL = URL(string: url),
            let username = urL.user,
			let hostname = urL.host,
            let path = URL(string: url)?.path,
			"postgres" == urL.scheme
             else {
                throw PostgreSQLError(identifier: "Bad Connection String",
                                 reason: "Config could not be parsed",
                                 possibleCauses: ["Foundation URL is unable to parse the provided connection string"],
                                 suggestedFixes: ["Check the connection string being passed"],
                                 source: .capture())
        }
		let database = String(path.dropFirst())
		self.init(hostname: hostname, port: urL.port, username: username, database: database, password: urL.password)
    }
}
