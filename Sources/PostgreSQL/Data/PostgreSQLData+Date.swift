import Foundation

extension Date: PostgreSQLDataConvertible {
    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataType`
    public static var postgreSQLDataType: PostgreSQLDataType { return .timestamp }

    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataArrayType`
    public static var postgreSQLDataArrayType: PostgreSQLDataType { return ._timestamp }

    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Date {
        guard let value = data.data else {
            throw PostgreSQLError(identifier: "data", reason: "Could not decode String from `null` data.", source: .capture())
        }
        switch data.format {
        case .text:
            switch data.type {
            case .timestamp: return try value.makeString().parseDate(format:  "yyyy-MM-dd HH:mm:ss")
            case .date: return try value.makeString().parseDate(format:  "yyyy-MM-dd")
            case .time: return try value.makeString().parseDate(format:  "HH:mm:ss")
            default: throw PostgreSQLError(identifier: "date", reason: "Could not parse Date from text data type: \(data.type).", source: .capture())
            }
        case .binary:
            switch data.type {
            case .timestamp, .time:
                let microseconds = try value.makeFixedWidthInteger(Int64.self)
                let seconds = Double(microseconds) / Double(_microsecondsPerSecond)
                return Date(timeInterval: seconds, since: _psqlDateStart)
            case .date:
                let days = try value.makeFixedWidthInteger(Int32.self)
                let seconds = days * _secondsInDay
                return Date(timeInterval: Double(seconds), since: _psqlDateStart)
            default: throw PostgreSQLError(identifier: "date", reason: "Could not parse Date from binary data type: \(data.type).", source: .capture())
            }
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return PostgreSQLData(type: .timestamp, format: .binary, data: Int64(self.timeIntervalSince(_psqlDateStart) * Double(_microsecondsPerSecond)).data)
    }
}

private let _microsecondsPerSecond: Int64 = 1_000_000
private let _secondsInDay: Int32 = 24 * 60 * 60
private let _psqlDateStart = Date(timeIntervalSince1970: 946_684_800) // values are stored as seconds before or after midnight 2000-01-01

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
            throw PostgreSQLError(identifier: "date", reason: "Malformed date: \(self)", source: .capture())
        }
        return date
    }
}
