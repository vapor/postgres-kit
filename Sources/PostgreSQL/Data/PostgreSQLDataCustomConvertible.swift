/// Capable of being converted to/from `PostgreSQLData`
public protocol PostgreSQLDataCustomConvertible {
    /// The data type this model prefers to parse in `convertFromPostgreSQLData`.
    /// Note: the type may be different still.
    /// If `nil`, this type has no preffered data type.
    static var preferredDataType: PostgreSQLDataType? { get }

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
    /// See `PostgreSQLDataCustomConvertible.preferredDataType`
    public static var preferredDataType: PostgreSQLDataType? { return nil }

    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> PostgreSQLData {
        return data
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return self
    }
}
