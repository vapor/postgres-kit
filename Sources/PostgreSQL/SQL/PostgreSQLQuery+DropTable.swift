extension PostgreSQLQuery {
    public static func drop(table: String, ifExists: Bool = false) -> PostgreSQLQuery {
        return .dropTable(.init(name: table, ifExists: ifExists))
    }
    
    public struct DropTable {
        public var name: String
        public var ifExists: Bool
        public init(name: String, ifExists: Bool = false) {
            self.name = name
            self.ifExists = ifExists
        }
    }
}

extension PostgreSQLSerializer {
    internal func serialize(_ drop: PostgreSQLQuery.DropTable) -> String {
        var sql: [String] = []
        sql.append("DROP TABLE")
        if drop.ifExists {
            sql.append("IF EXISTS")
        }
        sql.append(escapeString(drop.name))
        return sql.joined(separator: " ")
    }
}
