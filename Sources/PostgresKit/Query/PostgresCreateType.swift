/// The `CREATE TYPE` command is used to create a new types in a database.
///
/// See `PostgresCreateTypeBuilder`.
public struct PostgresCreateType: SQLExpression {
    /// Name of type to create.
    public var name: SQLExpression

    public var definition: Definition

    public enum Definition {
//        case composite /* https://github.com/vapor/postgres-kit/issues/151 */
//        case base      /* https://github.com/vapor/postgres-kit/issues/152 */
        case `enum`([String])
    }

    public init(name: SQLExpression, definition: Definition) {
        self.name = name
        self.definition = definition
    }

    /// Creates a new `PostgresCreateType` query for an `ENUM` type.
    public static func `enum`(name: SQLExpression, cases: String...) -> PostgresCreateType {
        return .enum(name: name, cases: cases)
    }

    /// Creates a new `PostgresCreateType` query for an `ENUM` type.
    public static func `enum`(name: SQLExpression, cases: [String]) -> PostgresCreateType {
        return PostgresCreateType(name: name, definition: .enum(cases))
    }
    
    public func serialize(to serializer: inout SQLSerializer) {
        serializer.write("CREATE ")
        serializer.write("TYPE ")
        self.name.serialize(to: &serializer)
        self.definition.serialize(to: &serializer)
    }
}

extension PostgresCreateType.Definition {
    func serialize(to serializer: inout SQLSerializer) {
        switch self {
        case .enum(let cases):
            serializer.write("AS ENUM ")
            SQLGroupExpression(cases.map { SQLLiteral.string($0) })
                .serialize(to: &serializer)
        }
    }
}
