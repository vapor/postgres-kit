extension OptionalType {
    /// See `PostgreSQLDataConvertible`.
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        let wrapped = try requirePostgreSQLDataCustomConvertible(WrappedType.self).convertFromPostgreSQLData(data)
        return Self.makeOptionalType(wrapped as? WrappedType)
    }

    /// See `PostgreSQLDataConvertible`.
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        if let wrapped = self.wrapped {
            return try requirePostgreSQLDataCustomConvertible(wrapped).convertToPostgreSQLData()
        } else {
            return PostgreSQLData(null: .void)
        }
    }
}

extension Optional: PostgreSQLDataConvertible {
    /// See `PostgreSQLDataConvertible`.
    public static var postgreSQLDataType: PostgreSQLDataType {
        return requirePostgreSQLDataCustomConvertible(Wrapped.self).postgreSQLDataType
    }

    /// See `PostgreSQLDataConvertible`.
    public static var postgreSQLDataArrayType: PostgreSQLDataType {
        return requirePostgreSQLDataCustomConvertible(Wrapped.self).postgreSQLDataArrayType
    }
}
