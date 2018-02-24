import COperatingSystem
import Foundation

/// Representable by a `JSONB` column on the PostgreSQL database.
public protocol PostgreSQLJSONCustomConvertible: PostgreSQLDataCustomConvertible, Codable { }

extension PostgreSQLJSONCustomConvertible {
    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataType`
    public static var postgreSQLDataType: PostgreSQLDataType { return .jsonb }

    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataArrayType`
    public static var postgreSQLDataArrayType: PostgreSQLDataType { return ._jsonb }

    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        guard let value = data.data else {
            throw PostgreSQLError(identifier: "data", reason: "Unable to decode PostgreSQL JSON from `null` data.", source: .capture())
        }

        switch data.type {
        case .jsonb:
            switch data.format {
            case .text: return try JSONDecoder().decode(Self.self, from: value)
            case .binary:
                assert(value[0] == 0x01)
                return try JSONDecoder().decode(Self.self, from: value[1...])
            }
        default: throw PostgreSQLError(identifier: "json", reason: "Could not decode \(Self.self) from data type: \(data.type).", source: .capture())
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return try PostgreSQLData(type: .jsonb, format: .text, data: JSONEncoder().encode(self))
    }
}

extension Dictionary: PostgreSQLJSONCustomConvertible where Key: Codable, Value: Codable { }
