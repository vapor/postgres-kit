import SQLKit

extension PostgresQuery {
    public struct Insert: SQLInsert {
        public typealias Identifier = PostgresQuery.Identifier
        public typealias ColumnIdentifier = PostgresQuery.ColumnIdentifier
        public typealias Expression = PostgresQuery.Expression
        
        public static func insert(table: Identifier) -> Insert {
            return self.init(table: table, columns: [], values: [])
        }
        
        private let table: Identifier
        public var columns: [ColumnIdentifier]
        public var values: [[Expression]]
        
        public func serialize(_ binds: inout [Encodable]) -> String {
            var sql: [String] = []
            sql.append("INSERT INTO")
            sql.append(self.table.serialize(&binds))
            sql.append("(" + self.columns.serialize(&binds) + ")")
            sql.append("VALUES")
            sql.append(self.values.map { "(" + $0.serialize(&binds) + ")"}.joined(separator: ", "))
            return sql.joined(separator: " ")
        }
    }
}
