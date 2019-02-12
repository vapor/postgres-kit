//import SQLKit
//
//extension PostgresQuery {
//    public struct DropTable: SQLDropTable {
//        public typealias Identifier = PostgresQuery.Identifier
//        
//        public static func dropTable(name: Identifier) -> DropTable {
//            return self.init(table: name, ifExists: false)
//        }
//        
//        public var table: PostgresQuery.Identifier
//        public var ifExists: Bool
//        
//        public func serialize(_ binds: inout [Encodable]) -> String {
//            var sql: [String] = []
//            sql.append("DROP TABLE")
//            if ifExists {
//                sql.append("IF EXISTS")
//            }
//            sql.append(table.serialize(&binds))
//            return sql.joined(separator: " ")
//        }
//    }
//}
