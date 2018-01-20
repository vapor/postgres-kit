import COperatingSystem
import Foundation

/// Representable by a `JSONB` column on the PostgreSQL database.
public protocol PostgreSQLJSONCustomConvertible: PostgreSQLDataCustomConvertible, Codable { }

extension PostgreSQLJSONCustomConvertible {
    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        guard let value = data.data else {
            fatalError()
        }

        switch data.type {
        case .jsonb:
            switch data.format {
            case .text: return try JSONDecoder().decode(Self.self, from: value)
            case .binary:
                assert(value[0] == 0x01)
                return try JSONDecoder().decode(Self.self, from: value[1...])
            }
        default: fatalError()
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return try PostgreSQLData(type: .jsonb, format: .text, data: JSONEncoder().encode(self))
    }
}
