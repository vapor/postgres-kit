extension FixedWidthInteger {
    /// See `PostgreSQLDataConvertible`.
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        switch data.storage {
        case .binary(let value):
            let i: Self?
            switch data.type {
            case .char, .bpchar: i = value.as(Int8.self, default: 0).bigEndian.cast(to: Self.self)
            case .int2: i = value.as(Int16.self, default: 0).bigEndian.cast(to: Self.self)
            case .int4, .oid, .regproc: i = value.as(Int32.self, default: 0).bigEndian.cast(to: Self.self)
            case .int8: i = value.as(Int64.self, default: 0).bigEndian.cast(to: Self.self)
            default: throw PostgreSQLError.decode(self, from: data)
            }
            guard let value = i else {
                throw PostgreSQLError.decode(self, from: data)
            }
            return value
        case .text(let string):
            switch data.type {
            case .char, .bpchar:
                guard string.count == 1, let char = Data(string.utf8).as(Int8.self, default: 0).bigEndian.cast(to: Self.self) else {
                    throw PostgreSQLError.decode(self, from: data)
                }
                return char
            default:
                guard let converted = Self(string) else {
                    throw PostgreSQLError.decode(self, from: data)
                }
                return converted
            }
        case .null: throw PostgreSQLError.decode(self, from: data)
        }
    }

    /// See `PostgreSQLDataConvertible`.
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        let type: PostgreSQLDataType
        switch Self.bitWidth {
        case 8: type = .char
        case 16: type = .int2
        case 32: type = .int4
        case 64: type = .int8
        default: fatalError("Integer bit width not supported: \(Self.bitWidth)")
        }
        return PostgreSQLData(type, binary: Data.of(bigEndian))
    }


    /// Safely casts one `FixedWidthInteger` to another.
}

extension Int: PostgreSQLDataConvertible {}
extension Int8: PostgreSQLDataConvertible {}
extension Int16: PostgreSQLDataConvertible {}
extension Int32: PostgreSQLDataConvertible {}
extension Int64: PostgreSQLDataConvertible {}

extension UInt: PostgreSQLDataConvertible {}
extension UInt8: PostgreSQLDataConvertible {}
extension UInt16: PostgreSQLDataConvertible {}
extension UInt32: PostgreSQLDataConvertible {}
extension UInt64: PostgreSQLDataConvertible {}
