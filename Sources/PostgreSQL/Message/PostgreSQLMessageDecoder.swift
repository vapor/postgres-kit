import Bits
import Foundation

/// Non-decoder wrapper for `_PostgreSQLMessageDecoder`.
final class PostgreSQLMessageDecoder {
    /// Create a new `PostgreSQLMessageDecoder`
    init() {}

    /// Encodes a `PostgreSQLMessage` to `Data`.
    func decode(_ data: Data) throws -> (PostgreSQLMessage, Int)? {
        let decoder = _PostgreSQLMessageDecoder(data: data)
        guard decoder.data.count >= 1 else {
            return nil
        }

        let type = try decoder.decode(Byte.self)
        guard try decoder.verifyLength() else {
            return nil
        }

        let message: PostgreSQLMessage
        switch type {
        case .E: message = try .errorResponse(decoder.decode())
        case .R: message = try .authenticationRequest(decoder.decode())
        case .S: message = try .parameterStatus(decoder.decode())
        case .K: message = try .backendKeyData(decoder.decode())
        case .Z: message = try .readyForQuery(decoder.decode())
        case .T: message = try .rowDescription(decoder.decode())
        case .D: message = try .dataRow(decoder.decode())
        case .C: message = try .close(decoder.decode())
        default:
            let string = String(bytes: [type], encoding: .ascii) ?? "n/a"
            fatalError("Unrecognized message type: \(string) (\(type)")
        }
        return (message, decoder.data.count)
    }
}

// MARK: Decoder / Single

internal final class _PostgreSQLMessageDecoder: Decoder, SingleValueDecodingContainer {
    /// See Decoder.codingPath
    var codingPath: [CodingKey]

    /// See Decoder.userInfo
    var userInfo: [CodingUserInfoKey: Any]

    /// The data being decoded.
    var data: Data

    /// Creates a new internal `_PostgreSQLMessageDecoder`.
    init(data: Data) {
        self.codingPath = []
        self.userInfo = [:]
        self.data = data
    }

    /// Extracts and verifies the data length.
    func verifyLength() throws -> Bool {
        guard let length = try extractLength() else {
            return false
        }

        guard data.count + MemoryLayout<Int32>.size >= length else {
            return false
        }

        return true
    }

    /// Extracts an Int32 length, returning `nil`
    /// if it doesn't exist.
    func extractLength() throws -> Int32? {
        guard data.count >= 4 else {
            // need length
            return nil
        }
        return try decode(Int32.self)
    }

    /// See Encoder.singleValueContainer
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }

    /// See SingleValueDecodingContainer.decode
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return self.data.unsafePopFirst()
    }

    /// See SingleValueDecodingContainer.decode
    func decode(_ type: Int16.Type) throws -> Int16 {
        var int: Int16 = 0
        int += Int16(self.data.unsafePopFirst() << 8)
        int += Int16(self.data.unsafePopFirst())
        return int
    }

    /// See SingleValueDecodingContainer.decode
    func decode(_ type: Int32.Type) throws -> Int32 {
        var int: Int32 = 0
        int += Int32(self.data.unsafePopFirst() << 24)
        int += Int32(self.data.unsafePopFirst() << 16)
        int += Int32(self.data.unsafePopFirst() << 8)
        int += Int32(self.data.unsafePopFirst())
        return int
    }

    /// See SingleValueDecodingContainer.decode
    func decode(_ type: String.Type) throws -> String {
        var bytes: [UInt8] = []
        parse: while true {
            let byte = self.data.unsafePopFirst()
            switch byte {
            case 0: break parse // c style strings
            default: bytes.append(byte)
            }
        }
        let data = Data(bytes: bytes)
        guard let string = String(data: data, encoding: .utf8) else {
            fatalError("Unsupported decode type: non-UTF8 string")
        }
        return string
    }

    /// See SingleValueDecodingContainer.decode
    func decode<T>(_ type: T.Type = T.self) throws -> T where T: Decodable {
        return try T(from: self)
    }

    // Unsupported

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey { fatalError("Unsupported decode type: keyed container") }
    func unkeyedContainer() throws -> UnkeyedDecodingContainer { fatalError("Unsupported decode type: unkeyed container") }
    func decodeNil() -> Bool { fatalError("Unsupported decode type: nil") }
    func decode(_ type: Bool.Type) throws -> Bool { fatalError("Unsupported decode type: \(type)") }
    func decode(_ type: Int.Type) throws -> Int { fatalError("Unsupported decode type: \(type)") }
    func decode(_ type: Int8.Type) throws -> Int8 { fatalError("Unsupported decode type: \(type)") }
    func decode(_ type: Int64.Type) throws -> Int64 { fatalError("Unsupported decode type: \(type)") }
    func decode(_ type: UInt.Type) throws -> UInt { fatalError("Unsupported decode type: \(type)") }
    func decode(_ type: UInt16.Type) throws -> UInt16 { fatalError("Unsupported decode type: \(type)") }
    func decode(_ type: UInt32.Type) throws -> UInt32 { fatalError("Unsupported decode type: \(type)") }
    func decode(_ type: UInt64.Type) throws -> UInt64 { fatalError("Unsupported decode type: \(type)") }
    func decode(_ type: Float.Type) throws -> Float { fatalError("Unsupported decode type: \(type)") }
    func decode(_ type: Double.Type) throws -> Double { fatalError("Unsupported decode type: \(type)") }
}
