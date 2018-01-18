import Service

/// Provides base `PostgreSQL` services such as database and connection.
public final class PostgreSQLProvider: Provider {
    /// See `Provider.repositoryName`
    public static let repositoryName = "fluent-postgresql"

    /// See `Provider.register`
    public func register(_ services: inout Services) throws {
        try services.register(DatabaseKitProvider())
        services.register(PostgreSQLConnectionConfig.self)
        services.register(PostgreSQLDatabaseConfig.self)
        services.register(PostgreSQLDatabase.self)
        var databases = DatabaseConfig()
        databases.add(database: PostgreSQLDatabase.self, as: .psql)
        services.register(databases)
    }

    /// See `Provider.boot`
    public func boot(_ worker: Container) throws { }
}

/// MARK: Services

extension PostgreSQLConnectionConfig: ServiceType {
    /// See `ServiceType.makeService(for:)`
    public static func makeService(for worker: Container) throws -> PostgreSQLConnectionConfig {
        return .default()
    }
}

extension PostgreSQLDatabaseConfig: ServiceType {
    /// See `ServiceType.makeService(for:)`
    public static func makeService(for worker: Container) throws -> PostgreSQLDatabaseConfig {
        return .default()
    }
}
extension PostgreSQLDatabase: ServiceType {
    /// See `ServiceType.makeService(for:)`
    public static func makeService(for worker: Container) throws -> PostgreSQLDatabase {
        return try .init(config: worker.make(for: PostgreSQLDatabase.self))
    }
}
