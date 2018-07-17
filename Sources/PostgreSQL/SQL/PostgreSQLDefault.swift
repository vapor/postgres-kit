public struct PostgreSQLDefaultLiteral: SQLDefaultLiteral {
    /// See `SQLDefaultLiteral`.
    public static var `default`: PostgreSQLDefaultLiteral {
        return .init()
    }
    
    /// See `SQLDefaultLiteral`.
    public func serialize(_ binds: inout [Encodable]) -> String {
        return "DEFAULT"
    }
}
