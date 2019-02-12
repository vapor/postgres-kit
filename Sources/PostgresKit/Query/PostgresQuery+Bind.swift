//import SQLKit
//
///// Representable as a `PostgreSQLExpression`.
//public protocol PostgresExpressionRepresentable {
//    /// Self converted to a `PostgresQuery.Expression`.
//    var postgresExpression: PostgresQuery.Expression { get }
//}
//
//extension PostgresQuery {
//    /// See `SQLBind`.
//    public struct Bind: SQLBind {
//        /// See `SQLBind`.
//        public static func encodable<E>(_ value: E) -> Bind
//            where E: Encodable
//        {
//            if let expr = value as? PostgresExpressionRepresentable {
//                return self.init(.expression(expr.postgresExpression))
//            } else {
//                return self.init(.encodable(value))
//            }
//        }
//        
//        /// Specific type of bind.
//        private enum Storage {
//            /// A `PostgreSQLExpression`.
//            case expression(PostgresQuery.Expression)
//            
//            /// A bound `Encodable` type.
//            case encodable(Encodable)
//        }
//        
//        /// Bind value.
//        private let storage: Storage
//        
//        private init(_ storage: Storage) {
//            self.storage = storage
//        }
//        
//        /// See `SQLSerializable`.
//        public func serialize(_ binds: inout [Encodable]) -> String {
//            switch self.storage {
//            case .expression(let expr): return expr.serialize(&binds)
//            case .encodable(let value):
//                binds.append(value)
//                return "$\(binds.count)"
//            }
//        }
//    }
//}
