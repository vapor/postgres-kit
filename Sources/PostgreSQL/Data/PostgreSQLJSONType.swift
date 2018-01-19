import COperatingSystem
import Foundation

/// Representable by a `JSONB` column on the PostgreSQL database.
public protocol PostgreSQLJSONType: PostgreSQLDataCustomConvertible, Codable { }

extension PostgreSQLJSONType {
    /// See `PostgreSQLDataCustomConvertible.preferredDataType`
    public static var preferredDataType: PostgreSQLDataType? { return .jsonb }

    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        guard let value = data.data else {
            fatalError()
        }

        switch data.type {
        case .jsonb:
            switch data.format {
            case .text: return try JSONDecoder().decode(Self.self, from: value)
            case .binary: fatalError()
            }
        default: fatalError()
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return try PostgreSQLData(type: .jsonb, format: .text, data: JSONEncoder().encode(self))
    }
}