//import SQLKit
//
//extension PostgresQuery {
//    public struct GroupBy: SQLGroupBy {
//        public typealias Expression = PostgresQuery.Expression
//        
//        private let expression: Expression
//        
//        public static func groupBy(_ expression: Expression) -> GroupBy {
//            return self.init(expression: expression)
//        }
//        
//        public func serialize(_ binds: inout [Encodable]) -> String {
//            return expression.serialize(&binds)
//        }
//    }
//}
