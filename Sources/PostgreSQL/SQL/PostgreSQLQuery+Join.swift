extension PostgreSQLQuery {
    public struct Join {
        /// Supported SQL `DataJoin` methods.
        public enum Method {
            /// (INNER) JOIN: Returns records that have matching values in both tables
            case inner
            /// LEFT (OUTER) JOIN: Return all records from the left table, and the matched records from the right table
            case left
            /// RIGHT (OUTER) JOIN: Return all records from the right table, and the matched records from the left table
            case right
            /// FULL (OUTER) JOIN: Return all records when there is a match in either left or right table
            case full
            /// CROSS JOIN
            case cross
        }

        /// `INNER`, `OUTER`, etc.
        public let method: Method
        
        /// Table to join
        public let table: TableName
        
        /// `ON`
        /// join_condition is an expression resulting in a value of type boolean
        /// (similar to a WHERE clause) that specifies which rows in a join are considered to match.
        public var condition: Predicate?
        
        /// Creates a new SQL `DataJoin`.
        public init(method: Method, table: TableName, condition: Predicate? = nil) {
            self.method = method
            self.condition = condition
            self.table = table
        }
    }
}
extension PostgreSQLSerializer {
    internal mutating func serialize(_ join: PostgreSQLQuery.Join, _ binds: inout [PostgreSQLData]) -> String {
        var sql: [String] = []
        sql.append(serialize(join.method))
        sql.append(serialize(join.table))
        if let condition = join.condition {
            sql.append("ON")
            sql.append(serialize(condition, &binds))
        }
        return sql.joined(separator: " ")
    }

    internal func serialize(_ method: PostgreSQLQuery.Join.Method) -> String {
        switch method {
        case .inner: return "INNER JOIN"
        case .left: return "LEFT JOIN"
        case .right: return "RIGHT JOIN"
        case .full: return "FULL JOIN"
        case .cross: return "CROSS JOIN"
        }
    }
}
