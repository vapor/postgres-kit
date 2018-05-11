import Bits
import NIO
import Foundation

// MARK: Decoder / Single

final class _PostgreSQLMessageDecoder: Decoder, SingleValueDecodingContainer {
    /// See Decoder.codingPath
    var codingPath: [CodingKey]

    /// See Decoder.userInfo
    var userInfo: [CodingUserInfoKey: Any]

    /// The data being decoded.
    var data: ByteBuffer

    /// Creates a new internal `_PostgreSQLMessageDecoder`.
    init(data: ByteBuffer) {
        self.codingPath = []
        self.userInfo = [:]
        self.data = data
    }

    /// See Encoder.singleValueContainer
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }

    /// See SingleValueDecodingContainer.decode
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        VERBOSE("_PostgreSQLMessageDecoder.decode(_: \(type))")
        return try data.requireReadInteger()
    }

    /// See SingleValueDecodingContainer.decode
    func decode(_ type: Int16.Type) throws -> Int16 {
        VERBOSE("_PostgreSQLMessageDecoder.decode(_: \(type))")
        return try data.requireReadInteger()
    }

    /// See SingleValueDecodingContainer.decode
    func decode(_ type: Int32.Type) throws -> Int32 {
        VERBOSE("_PostgreSQLMessageDecoder.decode(_: \(type))")
        return try data.requireReadInteger()
    }
    
    /// See SingleValueDecodingContainer.decode
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        VERBOSE("_PostgreSQLMessageDecoder.decode(_: \(type))")
        return try data.requireReadInteger()
    }

    /// See SingleValueDecodingContainer.decode
    func decode(_ type: String.Type) throws -> String {
        VERBOSE("_PostgreSQLMessageDecoder.decode(_: \(type))")
        return try data.requireReadNullTerminatedString()
    }

    /// See SingleValueDecodingContainer.decode
    func decode<T>(_ type: T.Type = T.self) throws -> T where T: Decodable {
        VERBOSE("_PostgreSQLMessageDecoder.decode(_: \(type))")
        if T.self == Data.self {
            let count = try Int(decode(Int32.self))
            switch count {
            case 0: return Data() as! T
            case 1...:
                let sub: Data = data.readData(length: count)!
                return sub as! T
            default: throw PostgreSQLError(identifier: "decoder", reason: "Illegal data row column value count: \(count)", source: .capture())
            }
        } else {
            return try T(from: self)
        }
    }

    /// See SingleValueDecodingContainer.decodeNil
    func decodeNil() -> Bool {
        VERBOSE("_PostgreSQLMessageDecoder.decodeNil()")
        if data.getInteger(at: data.readerIndex) == Int32(-1) {
            data.moveReaderIndex(forwardBy: MemoryLayout<Int32>.size)
            return true
        } else {
            return false
        }
    }

    /// See Decoder.container
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        VERBOSE("_PostgreSQLMessageDecoder.container(keyedBy: \(type))")
        let container = _PostgreSQLMessageKeyedDecoder<Key>(decoder: self)
        return KeyedDecodingContainer(container)
    }

    /// See Decoder.unkeyedContainer
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        VERBOSE("_PostgreSQLMessageDecoder.unkeyedContainer()")
        return _PostgreSQLMessageUnkeyedDecoder(decoder: self)
    }

    // Unsupported
    func decode(_ type: Bool.Type) throws -> Bool { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)", source: .capture()) }
    func decode(_ type: Int.Type) throws -> Int { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)", source: .capture()) }
    func decode(_ type: Int8.Type) throws -> Int8 { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)", source: .capture()) }
    func decode(_ type: Int64.Type) throws -> Int64 { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)", source: .capture()) }
    func decode(_ type: UInt.Type) throws -> UInt { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)", source: .capture()) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)", source: .capture()) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)", source: .capture()) }
    func decode(_ type: Float.Type) throws -> Float { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)", source: .capture()) }
    func decode(_ type: Double.Type) throws -> Double { throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decode type: \(type)", source: .capture()) }
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
        throw PostgreSQLError(identifier: "decoder", reason: "Unsupported decoding type: nested unkeyed container", source: .capture())
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
