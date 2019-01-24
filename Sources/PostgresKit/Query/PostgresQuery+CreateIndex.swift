//import SQLKit
//
//extension PostgresQuery {
//    public struct CreateIndex: SQLCreateIndex {
//        public typealias Identifier = PostgresQuery.Identifier
//        public typealias ColumnIdentifier = PostgresQuery.ColumnIdentifier
//        
//        public static func createIndex(name: Identifier) -> CreateIndex {
//            return self.init(name: name, columns: [], modifier: nil)
//        }
//        
//        private let name: Identifier
//        public var columns: [ColumnIdentifier]
//        public var modifier: Modifier?
//        
//        
//        public func serialize(_ binds: inout [Encodable]) -> String {
//            var sql: [String] = []
//            sql.append("CREATE")
//            if let modifier = self.modifier {
//                sql.append(modifier.serialize(&binds))
//            }
//            sql.append("INDEX")
//            sql.append(self.name.serialize(&binds))
//            if let table = columns.first?.table {
//                sql.append("ON")
//                sql.append(table.serialize(&binds))
//            }
//            sql.append("(" + columns.map { $0.name }.serialize(&binds) + ")")
//            return sql.joined(separator: " ")
//        }
//    }
//}
//
//extension PostgresQuery.CreateIndex {
//    public struct Modifier: SQLIndexModifier {
//        public static var unique: PostgresQuery.CreateIndex.Modifier {
//            return .init()
//        }
//        
//        public func serialize(_ binds: inout [Encodable]) -> String {
//            return "UNIQUE"
//        }
//    }
//}
