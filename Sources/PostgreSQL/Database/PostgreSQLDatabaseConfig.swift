/// Config options for a `PostgreSQLConnection`
public struct PostgreSQLDatabaseConfig {
    /// Creates a `PostgreSQLDatabaseConfig` with default settings.
    public static func `default`() -> PostgreSQLDatabaseConfig {
        return .init(hostname: "localhost", port: 5432, username: "postgres")
    }

    /// Destination hostname.
    public let hostname: String

    /// Destination port.
    public let port: UInt16

    /// Username to authenticate.
    public let username: String
    public let password: String?
    
    /// Creates a new `PostgreSQLDatabaseConfig`.
    public init(hostname: String, port: UInt16, username: String, password: String? = nil) {
        self.hostname = hostname
        self.port = port
        self.username = username
        self.password = password
    }
}
