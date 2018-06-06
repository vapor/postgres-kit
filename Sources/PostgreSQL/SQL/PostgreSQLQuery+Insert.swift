extension PostgreSQLQuery {
    public static func insert(
        into table: TableName,
        values: [String: Value],
        returning keys: Expression...
    ) -> PostgreSQLQuery {
        let insert = Insert(table: table, values: values, returning: keys)
        return .insert(insert)
    }

    public struct Insert {
        public var table: TableName
        public var values: [String: Value]
        public var returning: [Expression]
        
        public init(table: TableName, values: [String: Value], returning: [Expression] = []) {
            self.table = table
            self.values = values
            self.returning = returning
        }
    }
}

extension PostgreSQLSerializer {
    internal mutating func serialize(_ insert: PostgreSQLQuery.Insert, _ binds: inout [PostgreSQLData]) -> String {
        var sql: [String] = []
        sql.append("INSERT INTO")
        sql.append(serialize(insert.table))
        if !insert.values.isEmpty {
            sql.append(group(insert.values.keys.map(escapeString)))
            sql.append("VALUES")
            sql.append(group(insert.values.values.map { serialize($0, &binds) }))
        } else {
            sql.append("DEFAULT VALUES")
        }
        if !insert.returning.isEmpty {
            sql.append("RETURNING")
            sql.append(insert.returning.map(serialize).joined(separator: ", "))
        }
        return sql.joined(separator: " ")
    }
}
