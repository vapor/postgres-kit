extension PostgreSQLQuery {
    public static func create(storage: CreateTable.Storage = .permanent, table: String, ifNotExists: Bool = false, _ columns: ColumnDefinition..., constraints: [TableConstraint] = []) -> PostgreSQLQuery {
        return create(storage: storage, table: table, ifNotExists: ifNotExists, columns: columns, constraints: constraints)
    }
    
    public static func create(storage: CreateTable.Storage = .permanent, table: String, ifNotExists: Bool = false, columns: [ColumnDefinition], constraints: [TableConstraint] = []) -> PostgreSQLQuery {
        let query = CreateTable(
            storage: storage,
            ifNotExists: ifNotExists,
            name: table,
            columns: columns,
            constraints: constraints
        )
        return .createTable(query)
    }
    
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
        
        public init(storage: Storage = .permanent, ifNotExists: Bool = false, name: String, columns: [ColumnDefinition] = [], constraints: [TableConstraint]) {
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
