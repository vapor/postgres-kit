extension PostgreSQLQuery {
    public struct CreateTable {
        public enum Storage {
            case permanent
            case temporary
            case unlogged
        }
        public var storage: Storage
        public var ifNotExists: Bool
        public var name: String
        public var columns: [ColumnDefinition]
        public var constraints: [TableConstraint]
        // FIXME: ("FIXME: like")
        
        public init(storage: Storage = .permanent, ifNotExists: Bool = false, name: String, columns: [ColumnDefinition], constraints: [TableConstraint] = []) {
            self.storage = storage
            self.ifNotExists = ifNotExists
            self.name = name
            self.columns = columns
            self.constraints = constraints
        }
    }
    
}

extension PostgreSQLSerializer {
    internal func serialize(_ create: PostgreSQLQuery.CreateTable) -> String {
        var sql: [String] = []
        sql.append("CREATE")
        switch create.storage {
        case .permanent: break
        case .temporary: sql.append("TEMP")
        case .unlogged: sql.append("UNLOGGED")
        }
        sql.append("TABLE")
        if create.ifNotExists {
            sql.append("IF NOT EXISTS")
        }
        sql.append(escapeString(create.name))
        sql.append(group(create.columns.map(serialize) + create.constraints.map(serialize)))
        return sql.joined(separator: " ")
    }
}
