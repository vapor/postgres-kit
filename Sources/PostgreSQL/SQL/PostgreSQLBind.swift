/// Representable as a `PostgreSQLExpression`.
public protocol PostgreSQLExpressionRepresentable {
    /// Self converted to a `PostgreSQLExpression`.
    var postgreSQLExpression: PostgreSQLExpression { get }
}

/// PostgreSQL specific `SQLBind`.
public struct PostgreSQLBind: SQLBind {
    /// See `SQLBind`.
    public static func encodable<E>(_ value: E) -> PostgreSQLBind
        where E: Encodable
    {
        if let expr = value as? PostgreSQLExpressionRepresentable {
            return self.init(value: .expression(expr.postgreSQLExpression))
        } else {
            return self.init(value: .encodable(value))
        }
    }
    
    /// Specific type of bind.
    public enum Value {
        /// A `PostgreSQLExpression`.
        case expression(PostgreSQLExpression)
        
        /// A bound `Encodable` type.
        case encodable(Encodable)
    }
    
    /// Bind value.
    public var value: Value
    
    /// See `SQLSerializable`.
    public func serialize(_ binds: inout [Encodable]) -> String {
        switch value {
        case .expression(let expr): return expr.serialize(&binds)
        case .encodable(let value):
            binds.append(value)
            return "$\(binds.count)"
        }
    }
}
