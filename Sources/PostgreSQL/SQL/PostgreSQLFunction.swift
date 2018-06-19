public struct PostgreSQLFunction: SQLFunction {
    public typealias Argument = GenericSQLFunctionArgument<PostgreSQLExpression>
    
    public static func function(_ name: String, _ args: [Argument]) -> PostgreSQLFunction {
        return .init(name: name, arguments: args)
    }
    
    public let name: String
    public let arguments: [Argument]
    
    public func serialize(_ binds: inout [Encodable]) -> String {
        return name + "(" + arguments.map { $0.serialize(&binds) }.joined(separator: ", ") + ")"
    }
}

extension SQLSelectExpression where Expression.Function == PostgreSQLFunction {
    // custom
}
