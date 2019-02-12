//import SQLKit
//
//extension PostgresQuery {
//    public struct Join: SQLJoin {
//        /// See `SQLJoin`.
//        public typealias Identifier = PostgresQuery.Identifier
//        
//        /// See `SQLJoin`.
//        public typealias Expression = PostgresQuery.Expression
//        
//        /// See `SQLJoin`.
//        public static func join(method: Method, table: Identifier, expression: Expression) -> Join {
//            return self.init(method: method, table: table, expression: expression)
//        }
//        
//        /// See `SQLJoin`.
//        private let method: Method
//        
//        /// See `SQLJoin`.
//        private let table: Identifier
//        
//        /// See `SQLJoin`.
//        private let expression: Expression
//
//        
//        /// See `SQLSerializable`.
//        public func serialize(_ binds: inout [Encodable]) -> String {
//            return self.method.serialize(&binds) + " JOIN " + self.table.serialize(&binds) + " ON " + self.expression.serialize(&binds)
//        }
//    }
//}
//
//extension PostgresQuery.Join {
//    public struct Method: SQLJoinMethod {
//        public static var `default`: Method {
//            return .inner
//        }
//        
//        public static var inner: Method {
//            return .init(.inner)
//        }
//        
//        public static var left: Method {
//            return .init(.left)
//        }
//        
//        public static var right: Method {
//            return .init(.right)
//        }
//        
//        public static var full: Method {
//            return .init(.full)
//        }
//        
//        private enum Storage {
//            /// See `SQLJoinMethod`.
//            case inner
//            
//            /// See `SQLJoinMethod`.
//            case left
//            
//            /// See `SQLJoinMethod`.
//            case right
//            
//            /// See `SQLJoinMethod`.
//            case full
//        }
//        
//        private let storage: Storage
//        
//        private init(_ storage: Storage) {
//            self.storage = storage
//        }
//        
//        /// See `SQLSerializable`.
//        public func serialize(_ binds: inout [Encodable]) -> String {
//            switch self.storage {
//            case .inner: return "INNER"
//            case .left: return "LEFT"
//            case .right: return "RIGHT"
//            case .full: return "FULL"
//            }
//        }
//    }
//}
