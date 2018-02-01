import Async

/// Creates connections to an identified PostgreSQL database.
public final class PostgreSQLDatabase: Database {
    /// This database's configuration.
    public let config: PostgreSQLDatabaseConfig

    /// If non-nil, will log queries.
    public var logger: PostgreSQLLogger?

    /// Creates a new `PostgreSQLDatabase`.
    public init(config: PostgreSQLDatabaseConfig) {
        self.config = config
    }

    /// See `Database.makeConnection()`
    public func makeConnection(using connectionConfig: PostgreSQLConnectionConfig, on worker: Worker) -> Future<PostgreSQLConnection> {
        do {
            let client = try PostgreSQLConnection.connect(hostname: config.hostname, port: config.port, on: worker)
            client.logger = logger
            return client.authenticate(username: config.username, password: config.password).transform(to: client)
        } catch {
            return Future(error: error)
        }
    }
}

/// A connection created by a `PostgreSQLDatabase`.
extension PostgreSQLConnection: DatabaseConnection {
    /// See `DatabaseConnection.Config`
    public typealias Config = PostgreSQLConnectionConfig
}

extension DatabaseIdentifier {
    /// Default identifier for `PostgreSQLDatabase`.
    public static var psql: DatabaseIdentifier<PostgreSQLDatabase> {
        return .init("psql")
    }
}
