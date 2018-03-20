import Async

/// Creates connections to an identified PostgreSQL database.
public final class PostgreSQLDatabase: Database {
    /// This database's configuration.
    public let config: PostgreSQLDatabaseConfig

    /// If non-nil, will log queries.
    public var logger: PostgreSQLLogger?

    /// Caches oid -> table name data.
    internal private(set) var tableNameCache: PostgreSQLTableNameCache?

    /// Keeps a reference to the table name cache's event loop, so we can shut it down on deinit.
    private let eventLoopGroup: MultiThreadedEventLoopGroup

    /// Creates a new `PostgreSQLDatabase`.
    public init(config: PostgreSQLDatabaseConfig) {
        self.config = config
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numThreads: 1)
        self.tableNameCache = PostgreSQLTableNameCache(connection: makeConnection(on: eventLoopGroup))
    }

    deinit {
        eventLoopGroup.shutdownGracefully() {
            if let error = $0 {
                print("[PostgreSQL] shutting down event loop: \(error)")
            }
        }
    }

    /// See `Database.makeConnection()`
    public func makeConnection(on worker: Worker) -> Future<PostgreSQLConnection> {
        let config = self.config
        return Future.flatMap(on: worker) {
            return PostgreSQLConnection.connect(hostname: config.hostname, port: config.port, on: worker) { error in
                print("[PostgreSQL] \(error)")
            }.flatMap(to: PostgreSQLConnection.self) { client in
                client.logger = self.logger
                client.tableNameCache = self.tableNameCache
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
