import Foundation
/// Config options for a `PostgreSQLConnection`
public struct PostgreSQLDatabaseConfig {
    /// Creates a `PostgreSQLDatabaseConfig` with default settings.
    public static func `default`() -> PostgreSQLDatabaseConfig {
        return .init(hostname: "localhost", port: 5432, username: "postgres")
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
    public init(hostname: String, port: Int = 5432, username: String, database: String? = nil, password: String? = nil) {
        self.hostname = hostname
        self.port = port
        self.username = username
        self.database = database
        self.password = password
    }

    /// Creates a `PostgreSQLDatabaseConfig` frome a connection string.
    public init(url: String) throws {
        guard let urL = URL(string: url),
            let hostname = urL.host,
            let port = urL.port,
            let username = urL.user,
            let database = URL(string: url)?.path,
            database.count > 0
             else {
                throw PostgreSQLError(identifier: "Bad Connection String",
                                 reason: "Host could not be parsed",
                                 possibleCauses: ["Foundation URL is unable to parse the provided connection string"],
                                 suggestedFixes: ["Check the connection string being passed"],
                                 source: .capture())
        }
        self.hostname = hostname
        self.port = port
        self.username = username
        if database.hasPrefix("/") {
            self.database = database.dropFirst().description
        } else {
            self.database = database
        }
        self.password = urL.password
    }
}
