/// Builds `PostgresDropType` queries.
///
///     conn.drop(type: "meal").run()
///
/// See `SQLQueryBuilder` for more information.
public final class PostgresDropTypeBuilder: SQLQueryBuilder {
    /// `DropType` query being built.
    public var dropType: PostgresDropType

    /// See `SQLQueryBuilder`.
    public var database: SQLDatabase

    /// See `SQLQueryBuilder`.
    public var query: SQLExpression {
        return self.dropType
    }

    /// Creates a new `PostgresDropTypeBuilder`.
    public init(_ dropType: PostgresDropType, on database: SQLDatabase) {
        self.dropType = dropType
        self.database = database
    }

    /// The optional `IF EXISTS` clause suppresses the error that would normally
    /// result if the type does not exist.
    public func ifExists() -> Self {
        dropType.ifExists = true
        return self
    }

    /// The optional `CASCADE` clause drops other objects that depend on this type
    /// (such as table columns, functions, and operators), and in turn all objects
    /// that depend on those objects.
    public func cascade() -> Self {
        dropType.cascade = true
        return self
    }
}

// MARK: Connection

extension SQLDatabase {
    /// Creates a new `PostgresDropTypeBuilder`.
    ///
    ///     conn.drop(type: "meal").run()
    ///
    /// - parameters:
    ///     - type: Name of type to drop.
    /// - returns: `PostgresDropTypeBuilder`.
    public func drop(type name: String) -> PostgresDropTypeBuilder {
        return self.drop(type: SQLIdentifier(name))
    }

    /// Creates a new `PostgresDropTypeBuilder`.
    ///
    ///     conn.drop(type: "meal").run()
    ///
    /// - parameters:
    ///     - type: Name of type to drop.
    /// - returns: `PostgresDropTypeBuilder`.
    public func drop(type name: SQLExpression) -> PostgresDropTypeBuilder {
        return .init(.init(typeName: name), on: self)
    }
}
