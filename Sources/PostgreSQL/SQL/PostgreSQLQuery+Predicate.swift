extension PostgreSQLQuery {
    /// Represents one or more nestable SQL predicates joined by `AND` or `OR`.
    public indirect enum Predicate {
        /// All suported SQL `DataPredicate` comparisons.
        public enum ComparisonOperator {
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
        public enum InfixOperator {
            /// AND
            case and
            /// OR
            case or
        }
        
        public enum PrefixOperator {
            /// NOT
            case not
        }
        
        /// A collection of `DataPredicate` items joined by AND or OR.
        case infix(InfixOperator, Predicate, Predicate)
        
        case prefix(PrefixOperator, Predicate)
        
        /// A single `DataPredicate`.
        case predicate(Column, ComparisonOperator, Value)
    }
}


public func ==(_ lhs: PostgreSQLQuery.Column, _ rhs: PostgreSQLQuery.Value) -> PostgreSQLQuery.Predicate {
    return .predicate(lhs, .equal, rhs)
}

public func !=(_ lhs: PostgreSQLQuery.Column, _ rhs: PostgreSQLQuery.Value) -> PostgreSQLQuery.Predicate {
    return .predicate(lhs, .notEqual, rhs)
}

public func &&(_ lhs: PostgreSQLQuery.Predicate, _ rhs: PostgreSQLQuery.Predicate) -> PostgreSQLQuery.Predicate {
    return .infix(.and, lhs, rhs)
}

public func ||(_ lhs: PostgreSQLQuery.Predicate, _ rhs: PostgreSQLQuery.Predicate) -> PostgreSQLQuery.Predicate {
    return .infix(.or, lhs, rhs)
}

public prefix func !(_ lhs: PostgreSQLQuery.Predicate) -> PostgreSQLQuery.Predicate {
    return .prefix(.not, lhs)
}

extension PostgreSQLSerializer {
    internal mutating func serialize(_ predicate: PostgreSQLQuery.Predicate, _ binds: inout [PostgreSQLData]) -> String {
        switch predicate {
        case .infix(let infix, let left, let right):
            return serialize(left, &binds) + " " + serialize(infix) + " " + serialize(right, &binds)
        case .prefix(let prefix, let right):
            return serialize(prefix) + " " + serialize(right, &binds)
        case .predicate(let col, let comparison, let value):
            return serialize(col) + " " + serialize(comparison) + " " + serialize(value, &binds)
        }
    }
    
    internal func serialize(_ op: PostgreSQLQuery.Predicate.InfixOperator) -> String {
        switch op {
        case .and: return "AND"
        case .or: return "OR"
        }
    }
    
    internal func serialize(_ op: PostgreSQLQuery.Predicate.PrefixOperator) -> String {
        switch op {
        case .not: return "!"
        }
    }
    
    internal func serialize(_ op: PostgreSQLQuery.Predicate.ComparisonOperator) -> String {
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
