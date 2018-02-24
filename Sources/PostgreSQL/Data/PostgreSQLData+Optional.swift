import Async
import Foundation

extension OptionalType where Self.WrappedType: PostgreSQLDataCustomConvertible {
    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        let wrapped = try WrappedType.convertFromPostgreSQLData(data)
        return Self.makeOptionalType(wrapped)
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        if let wrapped = self.wrapped {
            return try wrapped.convertToPostgreSQLData()
        } else {
            return PostgreSQLData(type: .void, format: .binary, data: nil)
        }
    }
}

extension Optional: PostgreSQLDataCustomConvertible where Wrapped: PostgreSQLDataCustomConvertible {
    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataType`
    public static var postgreSQLDataType: PostgreSQLDataType {
        return Wrapped.postgreSQLDataType
    }


    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataArrayType`
    public static var postgreSQLDataArrayType: PostgreSQLDataType {
        return Wrapped.postgreSQLDataArrayType
    }
}

