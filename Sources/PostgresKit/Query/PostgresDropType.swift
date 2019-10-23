/// `DROP TYPE` query.
///
/// See `PostgresDropTypeBuilder`.
public struct PostgresDropType: SQLExpression {
    /// Type to drop.
    public let typeName: SQLExpression

    /// The optional `IF EXISTS` clause suppresses the error that would normally
    /// result if the type does not exist.
    public var ifExists: Bool

    /// The optional `CASCADE` clause drops other objects that depend on this type
    /// (such as table columns, functions, and operators), and in turn all objects
    /// that depend on those objects.
    public var cascade: Bool

    /// Creates a new `PostgresDropType`.
    public init(typeName: SQLExpression) {
        self.typeName = typeName
        self.ifExists = false
        self.cascade = false
    }

    /// See `SQLExpression`.
    public func serialize(to serializer: inout SQLSerializer) {
        serializer.write("DROP TYPE ")
        if self.ifExists {
            serializer.write("IF EXISTS ")
        }
        self.typeName.serialize(to: &serializer)
        if self.cascade {
            serializer.write(" CASCADE")
        }
    }
}
