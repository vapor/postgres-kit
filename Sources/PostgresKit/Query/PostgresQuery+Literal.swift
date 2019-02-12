//import SQLKit
//
//extension PostgresQuery {
//    public struct Literal: SQLLiteral {
//        public static func string(_ string: String) -> PostgresQuery.Literal {
//            return .init(.string(string))
//        }
//        
//        public static func numeric(_ string: String) -> PostgresQuery.Literal {
//            return .init(.numeric(string))
//        }
//        
//        public static var null: PostgresQuery.Literal {
//            return .init(.null)
//        }
//        
//        public static var `default`: PostgresQuery.Literal {
//            return .init(.default)
//        }
//        
//        public static func boolean(_ bool: Bool) -> PostgresQuery.Literal {
//            return .init(.boolean(bool))
//        }
//        
//        public var isNull: Bool {
//            switch self.storage {
//            case .null: return true
//            default: return false
//            }
//        }
//        
//        private enum Storage {
//            case string(String)
//            case numeric(String)
//            case boolean(Bool)
//            case `default`
//            case null
//        }
//        
//        private let storage: Storage
//        
//        private init(_ storage: Storage) {
//            self.storage = storage
//        }
//        
//        public init(stringLiteral value: String) {
//            self.init(.string(value))
//        }
//        
//        public func serialize(_ binds: inout [Encodable]) -> String {
//            switch self.storage {
//            case .string(let string): return "'" + string + "'"
//            case .numeric(let string): return string
//            case .boolean(let bool): return bool ? "TRUE" : "FALSE"
//            case .default: return "DEFAULT"
//            case .null: return "NULL"
//            }
//        }
//        
//    }
//}
