extension PostgreSQLQuery {
    public struct AlterTable {
        public var ifExists: Bool
        public var name: String
        public var addColumns: [ColumnDefinition]
        public var dropColumns: [String]
        public var addConstraints: [TableConstraint]
        public var dropConstraints: [String]
        
        public init(
            ifExists: Bool = false,
            name: String,
            addColumns: [ColumnDefinition],
            dropColumns: [String] = [],
            addConstraints: [TableConstraint],
            dropConstraints: [String]
        ) {
            self.ifExists = ifExists
            self.name = name
            self.addColumns = addColumns
            self.dropColumns = dropColumns
            self.addConstraints = addConstraints
            self.dropConstraints = dropConstraints
        }
    }
}

extension PostgreSQLSerializer {
    internal func serialize(_ alter: PostgreSQLQuery.AlterTable) -> String {
        var sql: [String] = []
        sql.append("ALTER TABLE")
        if alter.ifExists {
            sql.append("IF EXISTS")
        }
        sql.append(escapeString(alter.name))
        var actions: [String] = alter.addColumns.map { "ADD COLUMN " + serialize($0) }
        actions += alter.dropColumns.map { "DROP COLUMN " + escapeString($0) }
        actions += alter.addConstraints.map { "ADD CONSTSRAINT " + serialize($0) }
        actions += alter.dropConstraints.map { "DROP CONSTRAINT " + escapeString($0) }
        sql.append(group(actions))
        return sql.joined(separator: " ")
    }
}
