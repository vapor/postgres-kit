import Async
import Service

/// Provides base `PostgreSQL` services such as database and connection.
public final class PostgreSQLProvider: Provider {
    let identifier: DatabaseIdentifier<PostgreSQLDatabase>
    
    /// Creates a new `PostgreSQLProvider`.
    ///
    /// - Parameter identifier: the default identifier for the required Database.
    public init(default identifier: DatabaseIdentifier<PostgreSQLDatabase> = .psql) {
        self.identifier = identifier
    }

    /// See `Provider.register`
    public func register(_ services: inout Services) throws {
        try services.register(DatabaseKitProvider())
        services.register(PostgreSQLDatabaseConfig.self)
        services.register(PostgreSQLDatabase.self)
        var databases = DatabasesConfig()
        databases.add(database: PostgreSQLDatabase.self, as: self.identifier)
        services.register(databases)
    }

    /// See `Provider.boot`
    public func didBoot(_ worker: Container) throws -> Future<Void> {
        return .done(on: worker)
    }
}

/// MARK: Services

extension PostgreSQLDatabaseConfig: ServiceType {
    /// See `ServiceType.makeService(for:)`
    public static func makeService(for worker: Container) throws -> PostgreSQLDatabaseConfig {
        return try .default()
    }
}
extension PostgreSQLDatabase: ServiceType {
    /// See `ServiceType.makeService(for:)`
    public static func makeService(for worker: Container) throws -> PostgreSQLDatabase {
        return try .init(config: worker.make())
    }
}
