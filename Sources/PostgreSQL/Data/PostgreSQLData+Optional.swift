import Async
import Foundation

extension OptionalType {
    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        let wrapped = try requirePostgreSQLDataCustomConvertible(WrappedType.self).convertFromPostgreSQLData(data)
        return Self.makeOptionalType(wrapped as? WrappedType)
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        if let wrapped = self.wrapped {
            return try requirePostgreSQLDataCustomConvertible(wrapped).convertToPostgreSQLData()
        } else {
            return PostgreSQLData(type: .void, format: .binary, data: nil)
        }
    }
}

extension Optional: PostgreSQLDataCustomConvertible {
    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataType`
    public static var postgreSQLDataType: PostgreSQLDataType {
        return requirePostgreSQLDataCustomConvertible(Wrapped.self).postgreSQLDataType
    }


    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataArrayType`
    public static var postgreSQLDataArrayType: PostgreSQLDataType {
        return requirePostgreSQLDataCustomConvertible(Wrapped.self).postgreSQLDataArrayType
    }
}
