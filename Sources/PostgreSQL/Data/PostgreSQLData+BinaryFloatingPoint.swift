import Foundation

extension BinaryFloatingPoint {
    /// Return's this floating point's bit width.
    static var bitWidth: Int {
        return exponentBitCount + significandBitCount + 1
    }

    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataType`
    public static var postgreSQLDataType: PostgreSQLDataType {
        switch Self.bitWidth {
        case 32: return .float4
        case 64: return .float8
        default: fatalError("Unsupported floating point bit width: \(Self.bitWidth)")
        }
    }


    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataArrayType`
    public static var postgreSQLDataArrayType: PostgreSQLDataType {
        switch Self.bitWidth {
        case 32: return ._float4
        case 64: return ._float8
        default: fatalError("Unsupported floating point bit width: \(Self.bitWidth)")
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        guard let value = data.data else {
            throw PostgreSQLError(identifier: "binaryFloatingPoint", reason: "Could not decode \(Self.self) from `null` data.")
        }
        switch data.format {
        case .binary:
            switch data.type {
            case .float4: return Self.init(value.makeFloatingPoint(Float.self))
            case .float8: return Self.init(value.makeFloatingPoint(Double.self))
            case .char: return try Self.init(value.makeFixedWidthInteger(Int8.self))
            case .int2: return try Self.init(value.makeFixedWidthInteger(Int16.self))
            case .int4: return try Self.init(value.makeFixedWidthInteger(Int32.self))
            case .int8: return try Self.init(value.makeFixedWidthInteger(Int64.self))
            case .timestamp, .date, .time:
                let date = try Date.convertFromPostgreSQLData(data)
                return Self(date.timeIntervalSinceReferenceDate)
            default:
                throw PostgreSQLError(
                    identifier: "binaryFloatingPoint",
                    reason: "Could not decode \(Self.self) from binary data type: \(data.type)."
                )
            }
        case .text:
            let string = try data.decode(String.self)
            guard let converted = Double(string) else {
                throw PostgreSQLError(identifier: "binaryFloatingPoint", reason: "Could not decode \(Self.self) from string: \(string).")
            }
            return Self(converted)
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return PostgreSQLData(type: Self.postgreSQLDataType, format: .binary, data: data)
    }
}

extension Double: PostgreSQLDataCustomConvertible { }
extension Float: PostgreSQLDataCustomConvertible { }

extension Data {
    /// Converts this data to a floating-point number.
    internal func makeFloatingPoint<F>(_ type: F.Type = F.self) -> F where F: FloatingPoint {
        return Data(reversed()).unsafeCast()
    }
}


extension FloatingPoint {
    /// Big-endian bytes for this floating-point number.
    internal var data: Data {
        var bytes = [UInt8](repeating: 0, count: MemoryLayout<Self>.size)
        var copy = self
        memcpy(&bytes, &copy, bytes.count)
        return Data(bytes.reversed())
    }
}
