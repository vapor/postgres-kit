/// Capable of being converted to/from `PostgreSQLData`
public protocol PostgreSQLDataCustomConvertible {
    /// This type's preferred data type.
    static var postgreSQLDataType: PostgreSQLDataType { get }

    /// This type's preferred array type.
    static var postgreSQLDataArrayType: PostgreSQLDataType { get }

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
    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataType`
    public static var postgreSQLDataType: PostgreSQLDataType { return .void }

    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataArrayType`
    public static var postgreSQLDataArrayType: PostgreSQLDataType { return .void }

    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> PostgreSQLData {
        return data
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return self
    }
}
