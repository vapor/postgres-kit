import Async
import Service

/// Provides base `PostgreSQL` services such as database and connection.
public final class PostgreSQLProvider: Provider {
    /// Creates a new `PostgreSQLProvider`.
    public init() {}

    /// See `Provider.register`
    public func register(_ services: inout Services) throws {
        try services.register(DatabaseKitProvider())
        services.register(PostgreSQLDatabaseConfig.self)
        services.register(PostgreSQLDatabase.self)
        var databases = DatabasesConfig()
        databases.add(database: PostgreSQLDatabase.self, as: .psql)
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
