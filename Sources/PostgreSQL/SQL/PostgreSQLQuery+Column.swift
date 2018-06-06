extension PostgreSQLQuery {
    public struct Column: Hashable {
        public var table: String?
        public var name: String
        
        public init(table: String? = nil, name: String) {
            self.table = table
            self.name = name
        }
    }
}

extension PostgreSQLQuery.Column: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(name: value)
    }
}

extension PostgreSQLSerializer {
    internal func serialize(_ column: PostgreSQLQuery.Column) -> String {
        if let table = column.table {
            return escapeString(table) + "." + escapeString(column.name)
        } else {
            return escapeString(column.name)
        }
    }
}
