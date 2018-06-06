extension PostgreSQLQuery {
    public enum Expression {
        public static func function(_ name: String, _ parameters: Expression..., as alias: String? = nil) -> Expression {
            return .function(name, parameters, as: alias)
        }
        
        public static func function(_ name: String, _ parameters: [Expression], as alias: String? = nil) -> Expression {
            return .function(.init(name: name, parameters: parameters), alias: alias)
        }
        
        public static func column(_ column: Column, as alias: String? = nil) -> Expression {
            return .column(column, alias: alias)
        }
        
        public struct Function {
            var name: String
            var parameters: [Expression]
        }
        
        /// *
        case all
        case column(Column, alias: String?)
        case function(Function, alias: String?)
        case stringLiteral(String)
        case literal(String)
    }
}

extension PostgreSQLQuery.Expression: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .literal(value.description)
    }
}

extension PostgreSQLQuery.Expression: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .literal(value.description)
    }
}

extension PostgreSQLQuery.Expression: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .column(.init(stringLiteral: value), alias: nil)
    }
}

extension PostgreSQLSerializer {
    internal func serialize(_ expression: PostgreSQLQuery.Expression) -> String {
        switch expression {
        case .stringLiteral(let string): return stringLiteral(string)
        case .literal(let literal): return literal
        case .column(let column, let alias):
            if let alias = alias {
                return serialize(column) + " AS " + escapeString(alias)
            } else {
                return serialize(column)
            }
        case .function(let function, let alias):
            if let alias = alias {
                return serialize(function) + " AS " + escapeString(alias)
            } else {
                return serialize(function)
            }
        case .all: return "*"
        }
    }
    
    internal func serialize(_ function: PostgreSQLQuery.Expression.Function) -> String {
        return function.name + group(function.parameters.map(serialize))
    }
}
