/// Config options for a `PostgreSQLConnection`
public struct PostgreSQLConnectionConfig {
    /// Creates a `PostgreSQLConnectionConfig` with default settings.
    public static func `default`() -> PostgreSQLConnectionConfig {
        return .init()
    }

    /// Creates a new `PostgreSQLConnectionConfig`.
    public init() {}
}
