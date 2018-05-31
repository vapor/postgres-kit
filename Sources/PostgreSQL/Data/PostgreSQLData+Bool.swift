extension Bool: PostgreSQLDataConvertible {
    /// See `PostgreSQLDataConvertible`.
    public static var postgreSQLDataType: PostgreSQLDataType { return .bool }
    
    /// See `PostgreSQLDataConvertible`.
    public static var postgreSQLDataArrayType: PostgreSQLDataType { return ._bool }

    /// See `PostgreSQLDataConvertible`.
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Bool {
        switch data.storage {
        case .text(let value):
            guard value.count == 1 else {
                throw PostgreSQLError(identifier: "bool", reason: "Could not decode Bool from value: \(value)")
            }
            switch value[value.startIndex] {
            case "t": return true
            case "f": return false
            default: throw PostgreSQLError(identifier: "bool", reason: "Could not decode Bool from text: \(value)")
            }
        case .binary(let value):
            guard value.count == 1 else {
                throw PostgreSQLError(identifier: "bool", reason: "Could not decode Bool from value: \(value)")
            }
            switch value[0] {
            case 1: return true
            case 0: return false
            default: throw PostgreSQLError(identifier: "bool", reason: "Could not decode Bool from binary: \(value)")
            }
        case .null: throw PostgreSQLError(identifier: "bool", reason: "Could not decode Bool from null data.")
        }

    }

    /// See `PostgreSQLDataConvertible`.
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return PostgreSQLData(.bool, binary: self ? _true : _false)
    }
}

// MARK: Private

private let _true = Data([0x01])
private let _false = Data([0x00])
