/// Capable of being converted to/from `PostgreSQLData`
public protocol PostgreSQLDataCustomConvertible {
    /// Creates a `Self` from the supplied `PostgreSQLData`
    static func convertFromPostgreSQLData(from data: PostgreSQLData) throws -> Self

    /// Converts `Self` to a `PostgreSQLData`
    func convertToPostgreSQLData() throws -> PostgreSQLData
}
