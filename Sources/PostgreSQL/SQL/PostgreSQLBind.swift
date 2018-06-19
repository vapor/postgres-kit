public protocol PostgreSQLExpressionRepresentable {
    var postgreSQLExpression: PostgreSQLExpression { get }
}

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
    
    public enum Value {
        case expression(PostgreSQLExpression)
        case encodable(Encodable)
    }
    
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
