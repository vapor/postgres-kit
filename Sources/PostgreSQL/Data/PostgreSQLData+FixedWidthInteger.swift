import Foundation

extension FixedWidthInteger {
    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataType`
    public static var postgreSQLDataType: PostgreSQLDataType {
        switch Self.bitWidth {
        case 8: return .char
        case 16: return .int2
        case 32: return .int4
        case 64: return .int8
        default: fatalError("Integer bit width not supported: \(Self.bitWidth)")
        }
    }

    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataArrayType`
    public static var postgreSQLDataArrayType: PostgreSQLDataType {
        switch Self.bitWidth {
        case 8: return ._char
        case 16: return ._int2
        case 32: return ._int4
        case 64: return ._int8
        default: fatalError("Integer bit width not supported: \(Self.bitWidth)")
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        guard let value = data.data else {
            throw PostgreSQLError(identifier: "fixedWidthInteger", reason: "Could not decode \(Self.self) from `null` data.", source: .capture())
        }
        switch data.format {
        case .binary:
            switch data.type {
            case .char: return try safeCast(value.makeFixedWidthInteger(Int8.self))
            case .int2: return try safeCast(value.makeFixedWidthInteger(Int16.self))
            case .int4: return try safeCast(value.makeFixedWidthInteger(Int32.self))
            case .int8: return try safeCast(value.makeFixedWidthInteger(Int64.self))
            default: throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: ""))
            }
        case .text:
            let string = try value.makeString()
            guard let converted = Self(string) else {
                throw PostgreSQLError(identifier: "fixedWidthInteger", reason: "Could not decode \(Self.self) from text: \(string).", source: .capture())
            }
            return converted
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return PostgreSQLData(type: Self.postgreSQLDataType, format: .binary, data: self.data)
    }


    /// Safely casts one `FixedWidthInteger` to another.
    internal static func safeCast<I, V>(_ value: V, to type: I.Type = I.self) throws -> I where V: FixedWidthInteger, I: FixedWidthInteger {
        if let existing = value as? I {
            return existing
        }

        guard I.bitWidth >= V.bitWidth else {
            throw DecodingError.typeMismatch(type, .init(codingPath: [], debugDescription: "Bit width too wide: \(I.bitWidth) < \(V.bitWidth)"))
        }
        guard value <= I.max else {
            throw DecodingError.typeMismatch(type, .init(codingPath: [], debugDescription: "Value too large: \(value) > \(I.max)"))
        }
        guard value >= I.min else {
            throw DecodingError.typeMismatch(type, .init(codingPath: [], debugDescription: "Value too small: \(value) < \(I.min)"))
        }
        return I(value)
    }
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

extension Data {
    /// Converts this data to a fixed-width integer.
    internal func makeFixedWidthInteger<I>(_ type: I.Type = I.self) throws -> I where I: FixedWidthInteger {
        guard count >= (I.bitWidth / 8) else {
            throw PostgreSQLError(identifier: "fixedWidthData", reason: "Not enough bytes to decode \(I.self): \(count)/\(I.bitWidth / 8)", source: .capture())
        }
        return unsafeCast(to: I.self).bigEndian
    }
}

extension FixedWidthInteger {
    /// Big-endian bytes for this integer.
    internal var data: Data {
        var bytes = [UInt8](repeating: 0, count: Self.bitWidth / 8)
        var intNetwork = bigEndian
        memcpy(&bytes, &intNetwork, bytes.count)
        return Data(bytes)
    }
}
