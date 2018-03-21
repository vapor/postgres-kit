import Async

/// Creates connections to an identified PostgreSQL database.
public final class PostgreSQLDatabase: Database {
    /// This database's configuration.
    public let config: PostgreSQLDatabaseConfig

    /// If non-nil, will log queries.
    public var logger: PostgreSQLLogger?

    /// Creates a new `PostgreSQLDatabase`.
    public init(config: PostgreSQLDatabaseConfig, on worker: Worker) {
        self.config = config
    }

    /// See `Database.makeConnection()`
    public func makeConnection(on worker: Worker) -> Future<PostgreSQLConnection> {
        let config = self.config
        return Future.flatMap(on: worker) {
            return try PostgreSQLConnection.connect(hostname: config.hostname, port: config.port, on: worker) { error in
                print("[PostgreSQL] \(error)")
            }.flatMap(to: PostgreSQLConnection.self) { client in
                client.logger = self.logger
                return client.authenticate(
                    username: config.username,
                    database: config.database,
                    password: config.password
                ).transform(to: client)
            }
        }
    }
}

/// A connection created by a `PostgreSQLDatabase`.
extension PostgreSQLConnection: DatabaseConnection, BasicWorker { }

extension DatabaseIdentifier {
    /// Default identifier for `PostgreSQLDatabase`.
    public static var psql: DatabaseIdentifier<PostgreSQLDatabase> {
        return .init("psql")
    }
}
