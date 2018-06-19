/// Represents an `ALTER TABLE ...` query.
public struct PostgreSQLAlterTable: SQLAlterTable {
    /// See `SQLAlterTable`.
    public typealias ColumnDefinition = PostgreSQLColumnDefinition
    
    /// See `SQLAlterTable`.
    public typealias TableIdentifier = PostgreSQLTableIdentifier
    
    /// See `SQLAlterTable`.
    public static func alterTable(_ table: PostgreSQLTableIdentifier) -> PostgreSQLAlterTable {
        return .init(table: table)
    }
    
    /// Name of table to alter.
    public var table: PostgreSQLTableIdentifier
    
    /// See `SQLAlterTable`.
    public var columns: [PostgreSQLColumnDefinition]
    
    /// See `SQLAlterTable`.
    public var constraints: [PostgreSQLTableConstraint]
    
    
    /// Creates a new `AlterTable`.
    ///
    /// - parameters:
    ///     - table: Name of table to alter.
    public init(table: PostgreSQLTableIdentifier) {
        self.table = table
        self.columns = []
        self.constraints = []
    }
    
    /// See `SQLSerializable`.
    public func serialize(_ binds: inout [Encodable]) -> String {
        var sql: [String] = []
        sql.append("ALTER TABLE")
        sql.append(table.serialize(&binds))
        let actions = columns.map { "ADD COLUMN " + $0.serialize(&binds) } + constraints.map { "ADD " + $0.serialize(&binds) }
        sql.append(actions.joined(separator: ", "))
        return sql.joined(separator: " ")
    }
}
