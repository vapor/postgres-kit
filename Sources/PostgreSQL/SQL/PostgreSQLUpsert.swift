public struct PostgreSQLUpsert {
    /// See `SQLUpsert`.
    public typealias Identifier = PostgreSQLIdentifier
    
    /// See `SQLUpsert`.
    public typealias Expression = PostgreSQLExpression
    
    /// See `SQLUpsert`.
    public static func upsert(_ column: [PostgreSQLColumnIdentifier], _ values: [(Identifier, Expression)]) -> PostgreSQLUpsert {
        return self.init(columns: [.column(nil, .identifier("id"))], values: values)
    }
    
    /// See `SQLUpsert`.
    public var columns: [PostgreSQLColumnIdentifier]
    
    /// See `SQLUpsert`.
    public var values: [(Identifier, Expression)]
    
    /// See `SQLSerializable`.
    public func serialize(_ binds: inout [Encodable]) -> String {
        var sql: [String] = []
        sql.append("ON CONFLICT")
        sql.append("(" + columns.serialize(&binds) + ")")
        sql.append("DO UPDATE SET")
        sql.append(values.map { $0.0.serialize(&binds) + " = " + $0.1.serialize(&binds) }.joined(separator: ", "))
        return sql.joined(separator: " ")
    }
}

extension SQLInsertBuilder where Connection.Query.Insert == PostgreSQLInsert {
    public func onConflict<T, V, E>(_ key: KeyPath<T, V>, set value: E) -> Self where
        T: PostgreSQLTable, E: Encodable
    {
        let row = SQLQueryEncoder(PostgreSQLExpression.self).encode(value)
        let values = row.map { row -> (PostgreSQLIdentifier, PostgreSQLExpression) in
            return (.identifier(row.key), row.value)
        }
        insert.upsert = .upsert([.keyPath(key)], values)
        return self
    }
}
