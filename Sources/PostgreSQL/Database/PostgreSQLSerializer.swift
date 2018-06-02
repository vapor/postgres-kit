/// PostgreSQL-flavored `SQLSerializer`.
public final class PostgreSQLSerializer: SQLSerializer {
    public typealias Database = PostgreSQLDatabase
    
    /// The current placeholder offset used to create PostgreSQL
    /// placeholders for parameterized queries.
    public var placeholderOffset: Int
    
    /// Creates a new `PostgreSQLSQLSerializer`
    public init() {
        self.placeholderOffset = 1
    }
    
    /// See `SQLSerializer`
    public func makeEscapedString(from string: String) -> String {
        return "\"\(string)\""
    }
    
    /// See `SQLSerializer`
    public func makePlaceholder() -> String {
        defer { placeholderOffset += 1 }
        return "$\(placeholderOffset)"
    }
}
