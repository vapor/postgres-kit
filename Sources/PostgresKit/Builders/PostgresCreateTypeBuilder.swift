/// Builds `PostgresCreateType` queries.
///
///    conn.create(enum: "meal", cases: "breakfast", "lunch", "dinner")
///        .run()
///
/// See `SQLColumnBuilder` and `SQLQueryBuilder` for more information.
public final class PostgresCreateTypeBuilder: SQLQueryBuilder {
    /// `CreateType` query being built.
    public var createType: PostgresCreateType
    
    /// See `SQLQueryBuilder`.
    public var database: SQLDatabase
    
    /// See `SQLQueryBuilder`.
    public var query: SQLExpression {
        return self.createType
    }
    
    /// Creates a new `PostgresCreateTypeBuilder`.
    public init(_ createType: PostgresCreateType, on database: SQLDatabase) {
        self.createType = createType
        self.database = database
    }
}

// MARK: Connection

extension SQLDatabase {
    /// Creates a new `PostgresCreateTypeBuilder`.
    ///
    ///     conn.create(enum: "meal", cases: "breakfast", "lunch", "dinner")...
    ///
    /// - parameters:
    ///     - name: Name of ENUM type to create.
    ///     - cases: The cases of the ENUM type.
    /// - returns: `PostgresCreateTypeBuilder`.
    public func create(enum name: String, cases: String...) -> PostgresCreateTypeBuilder {
        return self.create(enum: name, cases: cases)
    }

    /// Creates a new `PostgresCreateTypeBuilder`.
    ///
    ///     conn.create(enum: "meal", cases: "breakfast", "lunch", "dinner")...
    ///
    /// - parameters:
    ///     - name: Name of ENUM type to create.
    ///     - cases: The cases of the ENUM type.
    /// - returns: `PostgresCreateTypeBuilder`.
    public func create(enum name: String, cases: [String]) -> PostgresCreateTypeBuilder {
        return self.create(enum: SQLIdentifier(name), cases: cases)
    }
    
    /// Creates a new `PostgresCreateTypeBuilder`.
    ///
    ///     conn.create(enum: SQLIdentifier("meal"), cases: "breakfast", "lunch", "dinner")...
    ///
    /// - parameters:
    ///     - name: Name of ENUM type to create.
    ///     - cases: The cases of the ENUM type.
    /// - returns: `PostgresCreateTypeBuilder`.
    public func create(enum name: SQLExpression, cases: String...) -> PostgresCreateTypeBuilder {
        return self.create(enum: name, cases: cases)
    }

    /// Creates a new `PostgresCreateTypeBuilder`.
    ///
    ///     conn.create(enum: SQLIdentifier("meal"), cases: "breakfast", "lunch", "dinner")...
    ///
    /// - parameters:
    ///     - name: Name of ENUM type to create.
    ///     - cases: The cases of the ENUM type.
    /// - returns: `PostgresCreateTypeBuilder`.
    public func create(enum name: SQLExpression, cases: [String]) -> PostgresCreateTypeBuilder {
        return .init(.init(name: name, definition: .enum(cases)), on: self)
    }
}
