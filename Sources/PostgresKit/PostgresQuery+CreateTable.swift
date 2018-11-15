import SQLKit

extension PostgresQuery {
    public struct CreateTable: SQLCreateTable {
        public typealias Identifier = PostgresQuery.Identifier
        public typealias ColumnDefinition = PostgresQuery.ColumnDefinition
        public typealias TableConstraint = PostgresQuery.TableConstraint
        
        public static func createTable(name: Identifier) -> CreateTable {
            return self.init(temporary: false, ifNotExists: false, table: name, columns: [], tableConstraints: [])
        }
        
        public var temporary: Bool
        public var ifNotExists: Bool
        public var table: PostgresQuery.Identifier
        public var columns: [PostgresQuery.ColumnDefinition]
        public var tableConstraints: [PostgresQuery.TableConstraint]
        
        public func serialize(_ binds: inout [Encodable]) -> String {
            var sql: [String] = []
            sql.append("CREATE")
            if temporary {
                sql.append("TEMPORARY")
            }
            sql.append("TABLE")
            if ifNotExists {
                sql.append("IF NOT EXISTS")
            }
            sql.append(table.serialize(&binds))
            let actions = columns.map { $0.serialize(&binds) } + tableConstraints.map { $0.serialize(&binds) }
            sql.append("(" + actions.joined(separator: ", ") + ")")
            return sql.joined(separator: " ")
        }
    }
}
