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
public final class PostgreSQLDropIndexBuilder<Connectable>: SQLQueryBuilder
    where Connectable: SQLConnectable, Connectable.Connection.Query == PostgreSQLQuery
{
    /// `AlterTable` query being built.
    public var dropIndex: PostgreSQLDropIndex
    
    /// See `SQLQueryBuilder`.
    public var connectable: Connectable
    
    /// See `SQLQueryBuilder`.
    public var query: PostgreSQLQuery {
        return .dropIndex(dropIndex)
    }
    
    /// Creates a new `SQLCreateIndexBuilder`.
    public init(_ dropIndex: PostgreSQLDropIndex, on connectable: Connectable) {
        self.dropIndex = dropIndex
        self.connectable = connectable
    }
}


extension SQLConnectable where Connection.Query == PostgreSQLQuery {
    /// Creates a `PostgreSQLDropIndexBuilder` for this connection.
    public func drop(index identifier: PostgreSQLIdentifier) -> PostgreSQLDropIndexBuilder<Self> {
        return .init(PostgreSQLDropIndex(identifier: identifier), on: self)
    }
}
