extension PostgreSQLQuery {
    public struct Insert {
        public var table: TableName
        public var columns: [String]
        public var values: [[Value]]
        public var returning: [Key]
        
        public init(table: TableName, columns: [String] = [], values: [[Value]] = [], returning: [Key] = []) {
            self.table = table
            self.columns = columns
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
            sql.append(group(insert.columns.map(escapeString)))
            sql.append("VALUES")
            sql.append(
                insert.values.map { group($0.map { serialize($0, &binds) }) }.joined(separator: ", ")
            )
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
