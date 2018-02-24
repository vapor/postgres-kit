import Foundation

extension Bool: PostgreSQLDataCustomConvertible {
    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataType`
    public static var postgreSQLDataType: PostgreSQLDataType { return .bool }
    
    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataArrayType`
    public static var postgreSQLDataArrayType: PostgreSQLDataType { return ._bool }

    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Bool {
        guard let value = data.data else {
            throw PostgreSQLError(identifier: "bool", reason: "Could not decode String from `null` data.", source: .capture())
        }
        guard value.count == 1 else {
            throw PostgreSQLError(identifier: "bool", reason: "Could not decode Bool from value: \(value)", source: .capture())
        }
        switch data.format {
        case .text:
            switch value[0] {
            case .t: return true
            case .f: return false
            default: throw PostgreSQLError(identifier: "bool", reason: "Could not decode Bool from text: \(value)", source: .capture())
            }
        case .binary:
            switch value[0] {
            case 1: return true
            case 0: return false
            default: throw PostgreSQLError(identifier: "bool", reason: "Could not decode Bool from binary: \(value)", source: .capture())
            }
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return PostgreSQLData(type: .bool, format: .binary, data: self ? _true : _false)
    }
}

private let _true = Data([0x01])
private let _false = Data([0x00])

