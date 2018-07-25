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
    
    /// DROP [ COLUMN ] [ IF EXISTS ] column_name [ RESTRICT | CASCADE ]
    /// DROP CONSTRAINT [ IF EXISTS ]  constraint_name [ RESTRICT | CASCADE ]
    public struct DropAction: SQLSerializable {
        /// Algorithm to use while dropping.
        public enum Method {
            /// `RESTRICT`
            case restrict
            /// `CASCADE`
            case cascade
        }
        
        /// Type of entity to drop.
        public enum Kind {
            /// Table column.
            case column
            /// Table constraint.
            case constraint
        }
        
        /// See `Kind`.
        public var kind: Kind
        
        /// If `true`, no error will be thrown if the entity does not exist.
        public var ifExists: Bool
        
        /// Name of the constraint or column to drop.
        public var identifier: PostgreSQLIdentifier
        
        /// Algorithm to use.
        public var method: Method?
        
        /// Creates a new `DropAction`.
        public init(
            _ kind: Kind,
            ifExists: Bool = false,
            _ identifier: PostgreSQLIdentifier,
            _ method: Method? = nil
        ) {
            self.kind = kind
            self.ifExists = ifExists
            self.identifier = identifier
            self.method = method
        }
        
        /// See `SQLSerializable`.
        public func serialize(_ binds: inout [Encodable]) -> String {
            var sql: [String] = []
            sql.append("DROP")
            switch kind {
            case .column: sql.append("COLUMN")
            case .constraint: sql.append("CONSTRAINT")
            }
            if ifExists {
                sql.append("IF EXISTS")
            }
            sql.append(identifier.serialize(&binds))
            if let method = method {
                switch method {
                case .cascade: sql.append("CASCADE")
                case .restrict: sql.append("RESTRICT")
                }
            }
            return sql.joined(separator: " ")
        }
    }
    
    /// Things to drop.
    public var dropActions: [DropAction]
    
    /// Creates a new `AlterTable`.
    ///
    /// - parameters:
    ///     - table: Name of table to alter.
    public init(table: PostgreSQLTableIdentifier) {
        self.table = table
        self.columns = []
        self.constraints = []
        self.dropActions = []
    }
    
    /// See `SQLSerializable`.
    public func serialize(_ binds: inout [Encodable]) -> String {
        var sql: [String] = []
        sql.append("ALTER TABLE")
        sql.append(table.serialize(&binds))
        let actions = columns.map { "ADD COLUMN " + $0.serialize(&binds) }
            + constraints.map { "ADD " + $0.serialize(&binds) }
            + dropActions.map { $0.serialize(&binds) }
        sql.append(actions.joined(separator: ", "))
        return sql.joined(separator: " ")
    }
}
