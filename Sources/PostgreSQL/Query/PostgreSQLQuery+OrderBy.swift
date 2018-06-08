extension PostgreSQLQuery {
    /// A SQL `ORDER BY` that determines the order of results.
    public struct OrderBy {
        /// Available order by directions for a `DataOrderBy`.
        public enum Direction {
            /// DESC
            case ascending
            
            /// ASC
            case descending
        }
        
        /// The columns to order.
        public var expression: Expression
        
        /// The direction to order the results.
        public var direction: Direction
        
        /// Creates a new SQL `DataOrderBy`
        public init(_ expression: Expression, direction: Direction) {
            self.expression = expression
            self.direction = direction
        }
    }
}

extension PostgreSQLSerializer {
    internal func serialize(_ orderBy: PostgreSQLQuery.OrderBy, _ binds: inout [PostgreSQLData]) -> String {
        return serialize(orderBy.expression) + " " + serialize(orderBy.direction)
    }
    
    internal func serialize(_ direction: PostgreSQLQuery.OrderBy.Direction) -> String {
        switch direction {
        case .ascending: return "ASC"
        case .descending: return "DESC"
        }
    }
}
