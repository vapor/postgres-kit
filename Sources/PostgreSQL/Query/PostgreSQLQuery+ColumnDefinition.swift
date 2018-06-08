extension PostgreSQLQuery {
    public struct ColumnDefinition {
        public static func column(
            _ name: String,
            _ dataType: DataType,
            collate: String? = nil,
            _ constraints: ColumnConstraint...
        ) -> ColumnDefinition {
            return .init(name: name, dataType: dataType, collate: collate, constraints: constraints)
        }
        
        public var name: String
        public var dataType: DataType
        public var isArray: Bool
        public var collate: String?
        public var constraints: [ColumnConstraint]
        
        public init(
            name: String,
            dataType: DataType,
            isArray: Bool = false,
            collate: String? = nil,
            constraints: [ColumnConstraint] = []
        ) {
            self.name = name
            self.dataType = dataType
            self.isArray = isArray
            self.collate = collate
            self.constraints = constraints
        }
    }
}

extension PostgreSQLSerializer {
    internal func serialize(_ column: PostgreSQLQuery.ColumnDefinition) -> String {
        var sql: [String] = []
        sql.append(escapeString(column.name))
        if column.isArray {
            sql.append(serialize(column.dataType) + "[]")
        } else {
            sql.append(serialize(column.dataType))
        }
        if let collate = column.collate {
            sql.append("COLLATE")
            sql.append(collate)
        }
        sql += column.constraints.map(serialize)
        return sql.joined(separator: " ")
    }
}
