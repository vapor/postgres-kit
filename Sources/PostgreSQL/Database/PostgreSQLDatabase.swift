/// Creates connections to an identified PostgreSQL database.
public final class PostgreSQLDatabase: Database, LogSupporting {
    /// See `LogSupporting`
    public static func enableLogging(_ logger: DatabaseLogger, on conn: PostgreSQLConnection) {
        conn.logger = logger
    }

    /// This database's configuration.
    public let config: PostgreSQLDatabaseConfig

    /// Creates a new `PostgreSQLDatabase`.
    public init(config: PostgreSQLDatabaseConfig) {
        self.config = config
    }

    /// See `Database.makeConnection()`
    public func newConnection(on worker: Worker) -> Future<PostgreSQLConnection> {
        let config = self.config
        do {
            return try PostgreSQLConnection.connect(to: config.serverAddress, transport: config.transportConfig, on: worker) { error in
                ERROR(error.localizedDescription)
            }.flatMap { client in
                return client.authenticate(
                    username: config.username,
                    database: config.database,
                    password: config.password
                ).transform(to: client)
            }
        } catch {
            return worker.future(error: error)
        }
    }
}

extension DatabaseIdentifier {
    /// Default identifier for `PostgreSQLDatabase`.
    public static var psql: DatabaseIdentifier<PostgreSQLDatabase> {
        return .init("psql")
    }
}
