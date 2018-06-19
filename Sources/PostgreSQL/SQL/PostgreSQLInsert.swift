public struct PostgreSQLInsert: SQLInsert {
    /// See `SQLInsert`.
    public static func insert(_ table: PostgreSQLTableIdentifier) -> PostgreSQLInsert {
        return .init(insert: .insert(table), returning: [])
    }
    
    /// See `SQLInsert`.
    public typealias TableIdentifier = PostgreSQLTableIdentifier
    
    /// See `SQLInsert`.
    public typealias ColumnIdentifier = PostgreSQLColumnIdentifier
    
    /// See `SQLInsert`.
    public typealias Expression = PostgreSQLExpression
    
    /// See `SQLInsert`.
    public typealias Upsert = PostgreSQLUpsert
    
    /// Root insert statement.
    private var insert: GenericSQLInsert<TableIdentifier, ColumnIdentifier, Expression, Upsert>

    /// `RETURNING *`
    public var returning: [PostgreSQLSelectExpression]
    
    /// See `SQLInsert`.
    public var columns: [PostgreSQLColumnIdentifier] {
        get { return insert.columns }
        set { insert.columns = newValue }
    }
    
    /// See `SQLInsert`.
    public var values: [[PostgreSQLExpression]] {
        get { return insert.values }
        set { insert.values = newValue}
    }
    
    /// See `SQLInsert`.
    public var upsert: PostgreSQLUpsert? {
        get { return insert.upsert }
        set { insert.upsert = newValue }
    }
    
    /// See `SQLSerializable`.
    public func serialize(_ binds: inout [Encodable]) -> String {
        if returning.isEmpty {
            return insert.serialize(&binds)
        } else {
            return insert.serialize(&binds) + " RETURNING " + returning.serialize(&binds)
        }
    }
}

extension SQLInsertBuilder where Connection.Query.Insert == PostgreSQLInsert {
    public func returning(_ exprs: PostgreSQLSelectExpression...) -> Self {
        insert.returning += exprs
        return self
    }
}
