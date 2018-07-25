/// PostgreSQL specific `SQLDropIndex`.
public struct PostgreSQLDropIndex: SQLDropIndex {
    /// See `SQLDropIndex`.
    public var identifier: PostgreSQLIdentifier
    
    /// See `SQLSerializable`.
    public func serialize(_ binds: inout [Encodable]) -> String {
        var sql: [String] = []
        sql.append("DROP INDEX")
        sql.append(identifier.serialize(&binds))
        return sql.joined(separator: " ")
    }
}

/// Builds `PostgreSQLDropIndex` queries.
public final class PostgreSQLDropIndexBuilder<Connection>: SQLQueryBuilder
    where Connection: SQLConnection, Connection.Query == PostgreSQLQuery
{
    /// `AlterTable` query being built.
    public var dropIndex: PostgreSQLDropIndex
    
    /// See `SQLQueryBuilder`.
    public var connection: Connection
    
    /// See `SQLQueryBuilder`.
    public var query: PostgreSQLQuery {
        return .dropIndex(dropIndex)
    }
    
    /// Creates a new `SQLCreateIndexBuilder`.
    public init(_ dropIndex: PostgreSQLDropIndex, on connection: Connection) {
        self.dropIndex = dropIndex
        self.connection = connection
    }
}


extension SQLConnection where Query == PostgreSQLQuery {
    /// Creates a `PostgreSQLDropIndexBuilder` for this connection.
    public func drop(index identifier: PostgreSQLIdentifier) -> PostgreSQLDropIndexBuilder<Self> {
        return .init(PostgreSQLDropIndex(identifier: identifier), on: self)
    }
}
