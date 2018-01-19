import Foundation

extension Date: PostgreSQLDataCustomConvertible {
    /// See `PostgreSQLDataCustomConvertible.preferredDataType`
    public static var preferredDataType: PostgreSQLDataType? { return .timestamp }

    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Date {
        guard let value = data.data else {
            throw PostgreSQLError(identifier: "data", reason: "Could not decode String from `null` data.")
        }
        switch data.format {
        case .text:
            switch data.type {
            case .timestamp: return try value.makeString().parseDate(format:  "yyyy-MM-dd HH:mm:ss")
            case .date: return try value.makeString().parseDate(format:  "yyyy-MM-dd")
            case .time: return try value.makeString().parseDate(format:  "HH:mm:ss")
            default: throw PostgreSQLError(identifier: "date", reason: "Could not parse Date from text data type: \(data.type).")
            }
        case .binary: throw PostgreSQLError(identifier: "date", reason: "Could not parse Date from binary data type: \(data.type).")
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return PostgreSQLData(type: .timestamp, format: .text, data: Data(description.utf8))
    }
}

extension String {
    /// Parses a Date from this string with the supplied date format.
    fileprivate func parseDate(format: String) throws -> Date {
        let formatter = DateFormatter()
        if contains(".") {
            formatter.dateFormat = format + ".SSSSSS"
        } else {
            formatter.dateFormat = format
        }
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        guard let date = formatter.date(from: self) else {
            throw PostgreSQLError(identifier: "date", reason: "Malformed date: \(self)")
        }
        return date
    }
}
