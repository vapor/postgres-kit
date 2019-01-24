//import SQLKit
//
//extension PostgresQuery {
//    public struct Update: SQLUpdate {
//        public typealias Identifier = PostgresQuery.Identifier
//        public typealias Expression = PostgresQuery.Expression
//        
//        public static func update(table: Identifier) -> Update {
//            return self.init(table: table, values: [], predicate: nil)
//        }
//        
//        public var table: Identifier
//        public var values: [(Identifier, Expression)]
//        public var predicate: Expression?
//        
//        public func serialize(_ binds: inout [Encodable]) -> String {
//            var sql: [String] = []
//            sql.append("UPDATE")
//            sql.append(self.table.serialize(&binds))
//            sql.append("SET")
//            sql.append(self.values.map { $0.0.serialize(&binds) + " = " + $0.1.serialize(&binds) }.joined(separator: ", "))
//            if let predicate = self.predicate {
//                sql.append("WHERE")
//                sql.append(predicate.serialize(&binds))
//            }
//            return sql.joined(separator: " ")
//        }
//    }
//}
//
