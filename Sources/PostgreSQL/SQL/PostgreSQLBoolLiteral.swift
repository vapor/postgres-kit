public enum PostgreSQLBoolLiteral: SQLBoolLiteral {
    /// See `SQLBoolLiteral`.
    public static var `true`: PostgreSQLBoolLiteral {
        return ._true
    }
    
    /// See `SQLBoolLiteral`.
    public static var `false`: PostgreSQLBoolLiteral {
        return ._false
    }
    
    case _true
    case _false
    
    /// See `SQLSerializable`.
    public func serialize(_ binds: inout [Encodable]) -> String {
        switch self {
        case ._true: return "TRUE"
        case ._false: return "FALSE"
        }
    }
}
