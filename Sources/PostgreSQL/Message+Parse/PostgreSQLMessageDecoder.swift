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
        case .E: message = try .error(decoder.decode())
        case .N: message = try .notice(decoder.decode())
        case .R: message = try .authenticationRequest(decoder.decode())
        case .S: message = try .parameterStatus(decoder.decode())
        case .K: message = try .backendKeyData(decoder.decode())
        case .Z: message = try .readyForQuery(decoder.decode())
        case .T: message = try .rowDescription(decoder.decode())
        case .D: message = try .dataRow(decoder.decode())
        case .C: message = try .close(decoder.decode())
        case .one: message = .parseComplete
        case .two: message = .bindComplete
        case .n: message = .noData
        case .t: message = try .parameterDescription(decoder.decode())
        default:
            let string = String(bytes: [type], encoding: .ascii) ?? "n/a"
            throw PostgreSQLError(
                identifier: "decoder",
                reason: "Unrecognized message type: \(string) (\(type)",
                possibleCauses: ["Connected to non-PostgreSQL database"],
                suggestedFixes: ["Connect to PostgreSQL database"]
            )
        }
        return (message, decoder.data.count)
    }
}

// MARK: Decoder / Single

fileprivate final class _PostgreSQLMessageDecoder: Decoder, SingleValueDecodingContainer {
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
        return try decode(fixedWidthInteger: Int16.self)
    }

    /// See SingleValueDecodingContainer.decode
    func decode(_ type: Int32.Type) throws -> Int32 {
        return try decode(fixedWidthInteger: Int32.self)
    }

    /// Decodes a fixed width integer.
    func decode<B>(fixedWidthInteger type: B.Type) throws -> B where B: FixedWidthInteger {
        return data.extract(B.self).bigEndian
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
        guard let string = String(data: data, encoding: .utf8) else { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: non-UTF8 string")}
        return string
    }

    /// See SingleValueDecodingContainer.decode
    func decode<T>(_ type: T.Type = T.self) throws -> T where T: Decodable {
        if T.self == Data.self {
            let count = try Int(decode(Int32.self))
            switch count {
            case 0: return Data() as! T
            case 1...:
                let sub: Data = data.subdata(in: data.startIndex..<data.index(data.startIndex, offsetBy: count))
                data = data.advanced(by: count)
                return sub as! T
            default: throw PostgreSQLError(identifier: "decoder", reason: "Illegal data row column value count: \(count)")
            }
        } else {
            return try T(from: self)
        }
    }

    /// See SingleValueDecodingContainer.decodeNil
    func decodeNil() -> Bool {
        guard data.count >= 4 else {
            return false
        }

        /// if Int32 decode == -1, then this should be decoding `Data?.none`
        let count = data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> Int32 in
            return pointer.withMemoryRebound(to: Int32.self, capacity: 1) { (pointer: UnsafePointer<Int32>) -> Int32 in
                return pointer.pointee.bigEndian
            }
        }
        switch count {
        case -1:
            data = data.advanced(by: MemoryLayout<Int32>.size)
            return true
        default: return false
        }
    }

    /// See Decoder.container
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        let container = _PostgreSQLMessageKeyedDecoder<Key>(decoder: self)
        return KeyedDecodingContainer(container)
    }

    /// See Decoder.unkeyedContainer
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return _PostgreSQLMessageUnkeyedDecoder(decoder: self)
    }

    // Unsupported
    func decode(_ type: Bool.Type) throws -> Bool { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)") }
    func decode(_ type: Int.Type) throws -> Int { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)") }
    func decode(_ type: Int8.Type) throws -> Int8 { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)") }
    func decode(_ type: Int64.Type) throws -> Int64 { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)") }
    func decode(_ type: UInt.Type) throws -> UInt { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)") }
    func decode(_ type: UInt16.Type) throws -> UInt16 { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)") }
    func decode(_ type: UInt32.Type) throws -> UInt32 { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)") }
    func decode(_ type: UInt64.Type) throws -> UInt64 { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)") }
    func decode(_ type: Float.Type) throws -> Float { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)") }
    func decode(_ type: Double.Type) throws -> Double { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)") }
}

// MARK: Keyed

fileprivate final class _PostgreSQLMessageKeyedDecoder<K>: KeyedDecodingContainerProtocol where K: CodingKey {
    typealias Key = K
    var codingPath: [CodingKey]
    var allKeys: [K]
    var decoder: _PostgreSQLMessageDecoder

    /// Creates a new internal `_PostgreSQLMessageKeyedDecoder`
    init(decoder: _PostgreSQLMessageDecoder) {
        self.codingPath = []
        self.allKeys = []
        self.decoder = decoder
    }

    // Map decode for key to decoder

    func contains(_ key: K) -> Bool { return true }
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool { return try decoder.decode(Bool.self) }
    func decode(_ type: Int.Type, forKey key: K) throws -> Int { return try decoder.decode(Int.self) }
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 { return try decoder.decode(Int8.self) }
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 { return try decoder.decode(Int16.self) }
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 { return try decoder.decode(Int32.self) }
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 { return try decoder.decode(Int64.self) }
    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt { return try decoder.decode(UInt.self) }
    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 { return try decoder.decode(UInt8.self) }
    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 { return try decoder.decode(UInt16.self) }
    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 { return try decoder.decode(UInt32.self) }
    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 { return try decoder.decode(UInt64.self) }
    func decode(_ type: Float.Type, forKey key: K) throws -> Float { return try decoder.decode(Float.self) }
    func decode(_ type: Double.Type, forKey key: K) throws -> Double { return try decoder.decode(Double.self) }
    func decode(_ type: String.Type, forKey key: K) throws -> String { return try decoder.decode(String.self) }
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable { return try decoder.decode(T.self) }
    func superDecoder() throws -> Decoder { return decoder }
    func superDecoder(forKey key: K) throws -> Decoder { return decoder }
    func decodeNil(forKey key: K) throws -> Bool { return decoder.decodeNil() }

    // Unsupported

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = _PostgreSQLMessageKeyedDecoder<NestedKey>(decoder: decoder)
        return KeyedDecodingContainer(container)
    }

    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decoding type: nested unkeyed container")
    }
}

/// MARK: Unkeyed

fileprivate final class _PostgreSQLMessageUnkeyedDecoder: UnkeyedDecodingContainer {
    var count: Int?
    var isAtEnd: Bool {
        return currentIndex == count
    }
    var currentIndex: Int
    var codingPath: [CodingKey]
    var decoder: _PostgreSQLMessageDecoder

    /// Creates a new internal `_PostgreSQLMessageUnkeyedDecoder`
    init(decoder: _PostgreSQLMessageDecoder) {
        self.codingPath = []
        self.decoder = decoder
        self.count = try! Int(decoder.decode(Int16.self))
        currentIndex = 0
    }

    func decode(_ type: Bool.Type) throws -> Bool { currentIndex += 1; return try decoder.decode(Bool.self) }
    func decode(_ type: Int.Type) throws -> Int { currentIndex += 1; return try decoder.decode(Int.self) }
    func decode(_ type: Int8.Type) throws -> Int8 { currentIndex += 1; return try decoder.decode(Int8.self) }
    func decode(_ type: Int16.Type) throws -> Int16 { currentIndex += 1; return try decoder.decode(Int16.self) }
    func decode(_ type: Int32.Type) throws -> Int32 { currentIndex += 1; return try decoder.decode(Int32.self) }
    func decode(_ type: Int64.Type) throws -> Int64 { currentIndex += 1; return try decoder.decode(Int64.self) }
    func decode(_ type: UInt.Type) throws -> UInt { currentIndex += 1; return try decoder.decode(UInt.self) }
    func decode(_ type: UInt8.Type) throws -> UInt8 { currentIndex += 1; return try decoder.decode(UInt8.self) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { currentIndex += 1; return try decoder.decode(UInt16.self) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { currentIndex += 1; return try decoder.decode(UInt32.self) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { currentIndex += 1; return try decoder.decode(UInt64.self) }
    func decode(_ type: Float.Type) throws -> Float { currentIndex += 1; return try decoder.decode(Float.self) }
    func decode(_ type: Double.Type) throws -> Double { currentIndex += 1; return try decoder.decode(Double.self) }
    func decode(_ type: String.Type) throws -> String { currentIndex += 1; return try decoder.decode(String.self) }
    func decodeNil() throws -> Bool {currentIndex += 1; return decoder.decodeNil() }
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable { currentIndex += 1; return try decoder.decode(T.self) }
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer { currentIndex += 1; return _PostgreSQLMessageUnkeyedDecoder(decoder: decoder) }
    func superDecoder() throws -> Decoder { return decoder }
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = _PostgreSQLMessageKeyedDecoder<NestedKey>(decoder: decoder)
        return KeyedDecodingContainer(container)
    }
}
