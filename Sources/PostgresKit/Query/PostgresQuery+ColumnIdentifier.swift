//import SQLKit
//
//extension PostgresQuery {
//    public struct ColumnIdentifier: SQLColumnIdentifier {
//        public static func column(name: PostgresQuery.Identifier, table: PostgresQuery.Identifier?) -> PostgresQuery.ColumnIdentifier {
//            return self.init(name: name, table: table)
//        }
//        
//        public var table: PostgresQuery.Identifier?
//        public var name: PostgresQuery.Identifier
//        
//        public typealias Identifier = PostgresQuery.Identifier
//        
//        public typealias StringLiteralType = String
//        
//        public init(name: PostgresQuery.Identifier, table: PostgresQuery.Identifier? = nil) {
//            self.name = name
//            self.table = table
//        }
//        
//        public init(stringLiteral value: String) {
//            self = .column(name: .identifier(value), table: nil)
//        }
//        
//        public func serialize(_ binds: inout [Encodable]) -> String {
//            if let table = table {
//                return table.serialize(&binds) + "." + self.name.serialize(&binds)
//            } else {
//                return self.name.serialize(&binds)
//            }
//        }
//    }
//}
