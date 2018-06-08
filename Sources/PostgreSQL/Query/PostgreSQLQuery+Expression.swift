extension PostgreSQLQuery {
    public enum Key {
        public static func function(_ name: String, _ parameters: [Expression]? = nil, as alias: String? = nil) -> Key {
            return .expression(.function(.init(name: name, parameters: parameters)), alias: alias)
        }
        
        public static var version: Key {
            return .function("version", [])
        }
        
        /// *
        case all
        case expression(Expression, alias: String?)
    }
    
    
    public struct Function {
        var name: String
        var parameters: [Expression]?
        
        public init(name: String, parameters: [Expression]? = nil) {
            self.name = name
            self.parameters = parameters
        }
    }
    
    public enum Expression {
        case all
        case column(Column)
        case function(Function)
        case stringLiteral(String)
        case literal(String)
    }
}

extension PostgreSQLQuery.Function: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(name: value)
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
        self = .stringLiteral(value.description)
    }
}

extension PostgreSQLQuery.Key: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .expression(.init(integerLiteral: value), alias: nil)
    }
}

extension PostgreSQLQuery.Key: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .expression(.init(floatLiteral: value), alias: nil)
    }
}

extension PostgreSQLQuery.Key: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .expression(.column(.init(stringLiteral: value)), alias: nil)
    }
}

extension PostgreSQLSerializer {
    internal func serialize(_ key: PostgreSQLQuery.Key) -> String {
        switch key {
        case .expression(let expression, let alias):
            if let alias = alias {
                return serialize(expression) + " AS " + escapeString(alias)
            } else {
                return serialize(expression)
            }
        case .all: return "*"
        }
    }
    
    internal func serialize(_ expression: PostgreSQLQuery.Expression) -> String {
        switch expression {
        case .all: return "*"
        case .stringLiteral(let string): return stringLiteral(string)
        case .literal(let literal): return literal
        case .column(let column): return serialize(column)
        case .function(let function): return serialize(function)
        }
    }
    
    internal func serialize(_ function: PostgreSQLQuery.Function) -> String {
        if let parameters = function.parameters {
            return function.name + group(parameters.map(serialize))
        } else {
            return function.name
        }
    }
}
