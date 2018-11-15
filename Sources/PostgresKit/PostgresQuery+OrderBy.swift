import SQLKit

extension PostgresQuery {
    public struct OrderBy: SQLOrderBy {
        public typealias Expression = PostgresQuery.Expression
        public typealias Direction = PostgresQuery.Direction
        
        private let expression: Expression
        private let direction: Direction
        
        public static func orderBy(_ expression: Expression, _ direction: Direction) -> OrderBy {
            return self.init(expression: expression, direction: direction)
        }
        
        public func serialize(_ binds: inout [Encodable]) -> String {
            return expression.serialize(&binds) + " " + direction.serialize(&binds)
        }
    }
}
