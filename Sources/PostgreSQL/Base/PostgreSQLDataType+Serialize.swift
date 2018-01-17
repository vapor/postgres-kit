import Foundation

extension PostgreSQLData {
    /// Serializes the `PostgreSQLData` to this parameter.
    func serialize(format: PostgreSQLFormatCode) throws -> Data? {
        switch format {
        case .binary: return try serializeBinary()
        case .text: return try serializeText()
        }
    }

    /// Serializes the `PostgreSQLData` to this parameter.
    private func serializeText() throws -> Data? {
        let serialized: Data?
        switch self {
        case .date(let date): serialized = Data(date.description.utf8)
        case .string, .null, .int8, .int16, .int32, .int, .uint8, .uint16, .uint32, .uint, .double, .float, .data, .point:
            fatalError("Unsupported serialize text: \(self)")
        }
        return serialized
    }

    /// Serializes the `PostgreSQLData` to this parameter.
    private func serializeBinary() throws -> Data? {
        let serialized: Data?
        switch self {
        case .string(let string): serialized = Data(string.utf8)
        case .null: serialized = nil
        case .int8(let int): serialized = Data(int.bytes)
        case .int16(let int): serialized = Data(int.bytes)
        case .int32(let int): serialized = Data(int.bytes)
        case .int(let int): serialized = Data(int.bytes)
        case .uint8(let int): serialized = Data(int.bytes)
        case .uint16(let int): serialized = Data(int.bytes)
        case .uint32(let int): serialized = Data(int.bytes)
        case .uint(let int): serialized = Data(int.bytes)
        case .double(let double): serialized = Data(double.bytes)
        case .float(let float): serialized = Data(float.bytes)
        case .data(let data): serialized = data
        case .point(let x, let y): serialized = Data(x.bytes) + Data(y.bytes)
        case .date:
            fatalError("Unsupported serialize binary: \(self)")
        }
        return serialized
    }
}

extension FixedWidthInteger {
    /// Big-endian bytes for this integer.
    fileprivate var bytes: [UInt8] {
        var bytes = [UInt8](repeating: 0, count: Self.bitWidth / 8)
        var intNetwork = bigEndian
        memcpy(&bytes, &intNetwork, bytes.count)
        return bytes
    }
}

extension FloatingPoint {
    /// Big-endian bytes for this floating-point number.
    fileprivate var bytes: [UInt8] {
        var bytes = [UInt8](repeating: 0, count: MemoryLayout<Self>.size)
        var copy = self
        memcpy(&bytes, &copy, bytes.count)
        return bytes.reversed()
    }
}
