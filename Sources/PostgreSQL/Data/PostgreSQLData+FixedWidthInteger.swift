import Foundation

extension FixedWidthInteger {
    /// See `PostgreSQLDataCustomConvertible.preferredDataType`
    public static var preferredDataType: PostgreSQLDataType? {
        switch bitWidth {
        case 8: return .char
        case 16: return .int2
        case 32: return .int4
        case 64: return .int8
        default: return nil
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        guard let value = data.data else {
            throw PostgreSQLError(identifier: "data", reason: "Could not decode String from `null` data.")
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
            guard let converted = try Self(data.decode(String.self)) else {
                fatalError()
            }
            return converted
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        let type: PostgreSQLDataType
        switch Self.bitWidth {
        case 8: type = .char
        case 16: type = .int2
        case 32: type = .int4
        case 64: type = .int8
        default: throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "Integer bit width not supported: \(Self.bitWidth)"))
        }
        return PostgreSQLData(type: type, format: .binary, data: self.data)
    }


    /// Safely casts one `FixedWidthInteger` to another.
    private static func safeCast<I, V>(_ value: V, to type: I.Type = I.self) throws -> I where V: FixedWidthInteger, I: FixedWidthInteger {
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

extension Int: PostgreSQLDataCustomConvertible {}
extension Int8: PostgreSQLDataCustomConvertible {}
extension Int16: PostgreSQLDataCustomConvertible {}
extension Int32: PostgreSQLDataCustomConvertible {}
extension Int64: PostgreSQLDataCustomConvertible {}

extension UInt: PostgreSQLDataCustomConvertible {}
extension UInt8: PostgreSQLDataCustomConvertible {}
extension UInt16: PostgreSQLDataCustomConvertible {}
extension UInt32: PostgreSQLDataCustomConvertible {}
extension UInt64: PostgreSQLDataCustomConvertible {}

extension Data {
    /// Converts this data to a fixed-width integer.
    internal func makeFixedWidthInteger<I>(_ type: I.Type = I.self) -> I where I: FixedWidthInteger {
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
