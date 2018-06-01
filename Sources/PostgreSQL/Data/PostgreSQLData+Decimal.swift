extension Decimal: PostgreSQLDataConvertible {
    /// See `PostgreSQLDataConvertible`
    public static var postgreSQLDataType: PostgreSQLDataType {
        return Double.postgreSQLDataType
    }

    /// See `PostgreSQLDataConvertible`
    public static var postgreSQLDataArrayType: PostgreSQLDataType {
        return Double.postgreSQLDataArrayType
    }

    /// See `PostgreSQLDataConvertible`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Decimal {
        return try Decimal(Double.convertFromPostgreSQLData(data))
    }

    /// See `PostgreSQLDataConvertible`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return try Double(description).convertToPostgreSQLData()
    }
}
