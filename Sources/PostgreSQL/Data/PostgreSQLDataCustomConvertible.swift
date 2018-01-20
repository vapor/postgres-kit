/// Capable of being converted to/from `PostgreSQLData`
public protocol PostgreSQLDataCustomConvertible {
    /// Creates a `Self` from the supplied `PostgreSQLData`
    static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self

    /// Converts `Self` to a `PostgreSQLData`
    func convertToPostgreSQLData() throws -> PostgreSQLData
}

extension PostgreSQLData {
    /// Gets a `String` from the supplied path or throws a decoding error.
    public func decode<T>(_ type: T.Type) throws -> T where T: PostgreSQLDataCustomConvertible {
        return try T.convertFromPostgreSQLData(self)
    }
}

extension PostgreSQLData: PostgreSQLDataCustomConvertible {
    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> PostgreSQLData {
        return data
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return self
    }
}
