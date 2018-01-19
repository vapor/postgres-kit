import Foundation

extension String: PostgreSQLDataCustomConvertible {
    /// See `PostgreSQLDataCustomConvertible.preferredDataType`
    public static var preferredDataType: PostgreSQLDataType? { return .text }

    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> String {
        guard let value = data.data else {
            throw PostgreSQLError(identifier: "data", reason: "Could not decode String from `null` data.")
        }
        switch data.format {
        case .text: return String(data: value, encoding: .utf8) !! "Non-utf8"
        case .binary:
            switch data.type {
            case .text, .name: return String(data: value, encoding: .utf8) !! "Non-utf8"
            default: throw PostgreSQLError(identifier: "data", reason: "Could not decode String from data type: \(data.type)")
            }
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return PostgreSQLData(type: .text, format: .binary, data: Data(utf8))
    }
}

extension Data {
    /// Convert the row's data into a string, throwing if invalid encoding.
    internal func makeString(encoding: String.Encoding = .utf8) throws -> String {
        guard let string = String(data: self, encoding: encoding) else {
            throw PostgreSQLError(identifier: "utf8String", reason: "Unexpected non-UTF8 string.")
        }

        return string
    }
}
