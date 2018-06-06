extension PostgreSQLQuery {
    /// Represents one or more nestable SQL predicates joined by `AND` or `OR`.
    public indirect enum Predicate {
        /// All suported SQL `DataPredicate` comparisons.
        public enum Comparison {
            /// =
            case equal
            /// !=, <>
            case notEqual
            /// <
            case lessThan
            /// >
            case greaterThan
            /// <=
            case lessThanOrEqual
            /// >=
            case greaterThanOrEqual
            /// IN
            case `in`
            /// NOT IN
            case notIn
            /// BETWEEN
            case between
            /// LIKE
            case like
            /// NOT LIKE
            case notLike
        }
        
        /// Supported data predicate relations.
        public enum Relation {
            /// AND
            case and
            /// OR
            case or
        }
        
        public enum Prefix {
            /// NOT
            case not
        }
        
        /// A collection of `DataPredicate` items joined by AND or OR.
        case group(Relation, [Predicate])
        
        case prefix(Prefix, Predicate)
        
        /// A single `DataPredicate`.
        case predicate(Column, Comparison, Value)
    }
}


public func ==(_ lhs: PostgreSQLQuery.Column, _ rhs: PostgreSQLQuery.Value) -> PostgreSQLQuery.Predicate {
    return .predicate(lhs, .equal, rhs)
}

public func !=(_ lhs: PostgreSQLQuery.Column, _ rhs: PostgreSQLQuery.Value) -> PostgreSQLQuery.Predicate {
    return .predicate(lhs, .notEqual, rhs)
}

public prefix func !(_ lhs: PostgreSQLQuery.Predicate) -> PostgreSQLQuery.Predicate {
    return .prefix(.not, lhs)
}

extension PostgreSQLSerializer {
    internal mutating func serialize(_ predicate: PostgreSQLQuery.Predicate, _ binds: inout [PostgreSQLData]) -> String {
        switch predicate {
        case .group(let infix, let filters):
            return filters.map { "(" + serialize($0, &binds) + ")" }.joined(separator: " " + serialize(infix) + " ")
        case .prefix(let prefix, let right):
            return serialize(prefix) + " " + serialize(right, &binds)
        case .predicate(let col, let comparison, let value):
            return serialize(col) + " " + serialize(comparison, value, &binds)
        }
    }
    
    internal func serialize(_ op: PostgreSQLQuery.Predicate.Relation) -> String {
        switch op {
        case .and: return "AND"
        case .or: return "OR"
        }
    }
    
    internal func serialize(_ op: PostgreSQLQuery.Predicate.Prefix) -> String {
        switch op {
        case .not: return "!"
        }
    }
    
    internal mutating func serialize(_ op: PostgreSQLQuery.Predicate.Comparison, _ value: PostgreSQLQuery.Value, _ binds: inout [PostgreSQLData]) -> String {
        switch (op, value) {
        case (.equal, .null): return "IS NULL"
        case (.notEqual, .null): return "IS NOT NULL"
        case (.in, .values(let values))
            where values.count == 0: return "0"
        case (.in, .values(let values))
            where values.count == 1: return serialize(.equal, values[0], &binds)
        case (.notIn, .values(let values))
            where values.count == 0: return "1"
        case (.notIn, .values(let values))
            where values.count == 1: return serialize(.notEqual, values[0], &binds)
        default: return serialize(op) + " " + serialize(value, &binds)
        }
    }
    
    internal func serialize(_ op: PostgreSQLQuery.Predicate.Comparison) -> String {
        switch op {
        case .between: return "BETWEEN"
        case .equal: return "="
        case .greaterThan: return ">"
        case .greaterThanOrEqual: return ">="
        case .in: return "IN"
        case .lessThan: return "<"
        case .lessThanOrEqual: return "<="
        case .like: return "LIKE"
        case .notEqual: return "!="
        case .notIn: return "NOT IN"
        case .notLike: return "NOT LIKE"
        }
    }
}
