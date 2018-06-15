extension PostgreSQLQuery {
    public struct TableName {
        public var name: String
        public var alias: String?
        
        public init(name: String, as alias: String? = nil) {
            self.name = name
            self.alias = alias
        }
    }
}

extension PostgreSQLQuery.TableName: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(name: value)
    }
}

extension PostgreSQLSerializer {
    func serialize(_ table: PostgreSQLQuery.TableName) -> String {
        if let alias = table.alias {
            return escapeString(table.name) + " AS " + escapeString(alias)
        } else {
            return escapeString(table.name)
        }
    }
}
