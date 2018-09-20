/// PostgreSQL specific `SQLInsert`.
public struct PostgreSQLInsert: SQLInsert {
    /// See `SQLInsert`.
    public static func insert(_ table: PostgreSQLTableIdentifier) -> PostgreSQLInsert {
        return self.init(table: table, columns: [], values: [], upsert: nil, returning: [])
    }
    
    /// See `SQLInsert`.
    public typealias TableIdentifier = PostgreSQLTableIdentifier
    
    /// See `SQLInsert`.
    public typealias ColumnIdentifier = PostgreSQLColumnIdentifier
    
    /// See `SQLInsert`.
    public typealias Expression = PostgreSQLExpression
    
    /// See `SQLInsert`.
    public typealias Upsert = PostgreSQLUpsert
    
    /// Table to insert into.
    public var table: TableIdentifier
    /// See `SQLInsert`.
    public var columns: [PostgreSQLColumnIdentifier]
    
    /// See `SQLInsert`.
    public var values: [[PostgreSQLExpression]]
    
    /// Optional "upsert" condition.
    public var upsert: PostgreSQLUpsert?
    
    /// `RETURNING *`
    public var returning: [PostgreSQLSelectExpression]
    
    /// See `SQLSerializable`.
    public func serialize(_ binds: inout [Encodable]) -> String {
        var sql: [String] = []
        sql.append("INSERT INTO")
        sql.append(table.serialize(&binds))
        sql.append("(" + columns.serialize(&binds) + ")")
        sql.append("VALUES")
        sql.append(values.map { "(" + $0.serialize(&binds) + ")"}.joined(separator: ", "))
        if let upsert = upsert {
            sql.append(upsert.serialize(&binds))
        }
        if !returning.isEmpty {
            sql.append("RETURNING")
            sql.append(returning.serialize(&binds))
        }
        return sql.joined(separator: " ")
    }
}

extension SQLInsertBuilder where Connectable.Connection.Query.Insert == PostgreSQLInsert {
    /// Adds a `RETURNING` expression to the insert query.
    public func returning(_ exprs: PostgreSQLSelectExpression...) -> Self {
        insert.returning += exprs
        return self
    }
}
