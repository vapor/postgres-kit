//import SQLKit
//
//extension PostgresQuery {
//    public struct Delete: SQLDelete {
//        public typealias Identifier = PostgresQuery.Identifier
//        public typealias Expression = PostgresQuery.Expression
//        
//        public static func delete(table: Identifier) -> Delete {
//            return self.init(table: table, predicate: nil)
//        }
//        
//        public var table: PostgresQuery.Identifier
//        public var predicate: PostgresQuery.Expression?
//        
//        public func serialize(_ binds: inout [Encodable]) -> String {
//            var sql: [String] = []
//            sql.append("DELETE FROM")
//            sql.append(table.serialize(&binds))
//            if let predicate = self.predicate {
//                sql.append("WHERE")
//                sql.append(predicate.serialize(&binds))
//            }
//            return sql.joined(separator: " ")
//        }
//    }
//}
