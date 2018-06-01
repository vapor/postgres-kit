//extension String: PostgreSQLDataConvertible {
//    /// See `PostgreSQLDataConvertible`.
//    public static var postgreSQLDataType: PostgreSQLDataType { return .text }
//
//    /// See `PostgreSQLDataConvertible`.
//    public static var postgreSQLDataArrayType: PostgreSQLDataType { return ._text }
//
//    /// See `PostgreSQLDataConvertible`.
//    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> String {
//      
//    }
//
//    /// See `PostgreSQLDataConvertible`.
//    public func convertToPostgreSQLData() throws -> PostgreSQLData {
//        return PostgreSQLData(.text, binary: Data(utf8))
//    }
//}
//
//
//extension Data {
//    /// Convert the row's data into a string, throwing if invalid encoding.
//    internal func makeString(encoding: String.Encoding = .utf8) throws -> String {
//        guard let string = String(data: self, encoding: encoding) else {
//            throw PostgreSQLError(identifier: "utf8String", reason: "Unexpected non-UTF8 string: \(hexDebug).")
//        }
//
//        return string
//    }
//}
