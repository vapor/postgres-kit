import Foundation

extension BinaryFloatingPoint {
    /// See `PostgreSQLDataCustomConvertible.preferredDataType`
    public static var preferredDataType: PostgreSQLDataType? {
        switch exponentBitCount + significandBitCount + 1 {
        case 32: return .float4
        case 64: return .float8
        default: return nil
        }
    }

    /// Return's this floating point's bit width.
    static var bitWidth: Int {
        return exponentBitCount + significandBitCount + 1
    }

    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        guard let value = data.data else {
            throw PostgreSQLError(identifier: "data", reason: "Could not decode String from `null` data.")
        }
        switch data.format {
        case .binary:
            switch data.type {
            case .float4: return Self.init(value.makeFloatingPoint(Float.self))
            case .float8: return Self.init(value.makeFloatingPoint(Double.self))
            case .char: return Self.init(value.makeFixedWidthInteger(Int8.self))
            case .int2: return Self.init(value.makeFixedWidthInteger(Int16.self))
            case .int4: return Self.init(value.makeFixedWidthInteger(Int32.self))
            case .int8: return Self.init(value.makeFixedWidthInteger(Int64.self))
            default: throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: ""))
            }
        case .text:
            guard let converted = try Double(data.decode(String.self)) else {
                fatalError()
            }
            return Self(converted)
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        let type: PostgreSQLDataType
        switch Self.bitWidth {
        case 32: type = .float4
        case 64: type = .float8
        default: throw PostgreSQLError(
            identifier: "floatingPointBitWidth",
            reason: "Unsupported floating point bit width: \(Self.bitWidth)"
            )
        }
        return PostgreSQLData(type: type, format: .binary, data: data)
    }
}

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
