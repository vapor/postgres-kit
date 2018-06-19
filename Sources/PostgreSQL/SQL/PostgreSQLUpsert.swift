public struct PostgreSQLUpsert: SQLUpsert {
    /// See `SQLUpsert`.
    public typealias Identifier = PostgreSQLIdentifier
    
    /// See `SQLUpsert`.
    public typealias Expression = PostgreSQLExpression
    
    /// See `SQLUpsert`.
    public static func upsert(_ values: [(Identifier, Expression)]) -> PostgreSQLUpsert {
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
