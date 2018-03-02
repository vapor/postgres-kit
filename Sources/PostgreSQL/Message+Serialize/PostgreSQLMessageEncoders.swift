import Bits
import Foundation

// FIXME: update to byte buffer at some point

// MARK: Encoder / Single

/// Internal `Encoder` implementation for the `PostgreSQLMessageEncoder`.
internal final class _PostgreSQLMessageEncoder: Encoder, SingleValueEncodingContainer {
    /// See Encoder.codingPath
    var codingPath: [CodingKey]

    /// See Encoder.userInfo
    var userInfo: [CodingUserInfoKey: Any]

    /// The data currently being encoded
    var data: Data

    /// Creates a new internal `_PostgreSQLMessageEncoder`
    init() {
        self.codingPath = []
        self.userInfo = [:]
        /// Start with 4 bytes for the int32 size chunk
        self.data = Data([0, 0, 0, 0])
    }

    /// Updates the int32 size chunk in the data.
    func updateSize() {
        let size = numericCast(data.count) as Int32
        data.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<Int32>) in
            pointer.pointee = size.bigEndian
        }
    }

    /// See Encoder.singleValueContainer
    func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }

    /// See SingleValueEncodingContainer.encode
    func encode(_ value: String) throws {
        let stringData = Data(value.utf8)
        self.data.append(stringData + [0]) // c style string
    }

    /// See SingleValueEncodingContainer.encode
    func encode(_ value: Int8) throws {
        self.data.append(numericCast(value))
    }

    /// See SingleValueEncodingContainer.encode
    func encode(_ value: UInt8) throws {
        self.data.append(value)
    }

    /// See SingleValueEncodingContainer.encode
    func encode(_ value: Int16) throws {
        var value = value.bigEndian
        withUnsafeBytes(of: &value) { buffer in
            let buffer = buffer.unsafeBaseAddress.assumingMemoryBound(to: UInt8.self)
            self.data.append(buffer, count: 2)
        }
    }

    /// See SingleValueEncodingContainer.encode
    func encode(_ value: Int32) throws {
        var value = value.bigEndian
        withUnsafeBytes(of: &value) { buffer in
            let buffer = buffer.unsafeBaseAddress.assumingMemoryBound(to: UInt8.self)
            self.data.append(buffer, count: 4)
        }
    }

    /// See SingleValueEncodingContainer.encode
    func encode(_ value: Int64) throws {
        var value = value.bigEndian
        withUnsafeBytes(of: &value) { buffer in
            let buffer = buffer.unsafeBaseAddress.assumingMemoryBound(to: UInt8.self)
            self.data.append(buffer, count: 8)
        }
    }

    /// See SingleValueEncodingContainer.encode
    func encode<T>(_ value: T) throws where T : Encodable {
        if T.self == Data.self {
            let sub = value as! Data
            try encode(Int32(sub.count))
            self.data += sub
        } else {
            try value.encode(to: self)
        }
    }

    /// See Encoder.container
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = _PostgreSQLMessageKeyedEncoder<Key>(encoder: self)
        return KeyedEncodingContainer(container)
    }

    /// See Encoder.unkeyedContainer
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return _PostgreSQLMessageUnkeyedEncoder(encoder: self)
    }

    // Unsupported

    func encode(_ value: Int) throws { throw PostgreSQLError(identifier: "encoder", reason: "Unsupported type: \(type(of: value))", source: .capture()) }
    func encode(_ value: UInt) throws { throw PostgreSQLError(identifier: "encoder", reason: "Unsupported type: \(type(of: value))", source: .capture()) }
    func encode(_ value: UInt16) throws { throw PostgreSQLError(identifier: "encoder", reason: "Unsupported type: \(type(of: value))", source: .capture()) }
    func encode(_ value: UInt32) throws { throw PostgreSQLError(identifier: "encoder", reason: "Unsupported type: \(type(of: value))", source: .capture()) }
    func encode(_ value: UInt64) throws { throw PostgreSQLError(identifier: "encoder", reason: "Unsupported type: \(type(of: value))", source: .capture()) }
    func encode(_ value: Float) throws { throw PostgreSQLError(identifier: "encoder", reason: "Unsupported type: \(type(of: value))", source: .capture()) }
    func encode(_ value: Double) throws { throw PostgreSQLError(identifier: "encoder", reason: "Unsupported type: \(type(of: value))", source: .capture()) }
    func encode(_ value: Bool) throws { throw PostgreSQLError(identifier: "encoder", reason: "Unsupported type: \(type(of: value))", source: .capture()) }
    func encodeNil() throws { throw PostgreSQLError(identifier: "encoder", reason: "Unsupported type: nil", source: .capture()) }
}

fileprivate final class _PostgreSQLMessageKeyedEncoder<K>: KeyedEncodingContainerProtocol where K: CodingKey {
    typealias Key = K
    var codingPath: [CodingKey]
    let encoder: _PostgreSQLMessageEncoder

    init(encoder: _PostgreSQLMessageEncoder) {
        self.encoder = encoder
        self.codingPath = []
    }

    func encodeNil(forKey key: K) throws { try encoder.encodeNil() }
    func encode(_ value: Bool, forKey key: K) throws { try encoder.encode(value) }
    func encode(_ value: Int, forKey key: K) throws { try encoder.encode(value) }
    func encode(_ value: Int8, forKey key: K) throws { try encoder.encode(value) }
    func encode(_ value: Int16, forKey key: K) throws { try encoder.encode(value) }
    func encode(_ value: Int32, forKey key: K) throws { try encoder.encode(value) }
    func encode(_ value: Int64, forKey key: K) throws { try encoder.encode(value) }
    func encode(_ value: UInt, forKey key: K) throws { try encoder.encode(value) }
    func encode(_ value: UInt8, forKey key: K) throws { try encoder.encode(value) }
    func encode(_ value: UInt16, forKey key: K) throws { try encoder.encode(value) }
    func encode(_ value: UInt32, forKey key: K) throws { try encoder.encode(value) }
    func encode(_ value: UInt64, forKey key: K) throws { try encoder.encode(value) }
    func encode(_ value: Float, forKey key: K) throws { try encoder.encode(value) }
    func encode(_ value: Double, forKey key: K) throws { try encoder.encode(value) }
    func encode(_ value: String, forKey key: K) throws { try encoder.encode(value) }
    func encode<T>(_ value: T, forKey key: K) throws where T : Encodable { try encoder.encode(value) }
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K)
        -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey { return encoder.container(keyedBy: NestedKey.self) }
    func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer { return encoder.unkeyedContainer() }
    func superEncoder() -> Encoder { return encoder }
    func superEncoder(forKey key: K) -> Encoder { return encoder }

    func encodeIfPresent<T>(_ value: T?, forKey key: K) throws where T : Encodable {
        if T.self == Data.self {
            if let data = value {
                try encoder.encode(data)
            } else {
                try encoder.encode(Int32(-1)) // indicate nil data
            }
        } else {
            if let value = value {
                try encoder.encode(value)
            } else {
                try encoder.encodeNil()
            }
        }
    }
}

/// MARK: Unkeyed

fileprivate final class _PostgreSQLMessageUnkeyedEncoder: UnkeyedEncodingContainer {
    var count: Int
    var codingPath: [CodingKey]
    let encoder: _PostgreSQLMessageEncoder
    let countOffset: Int

    init(encoder: _PostgreSQLMessageEncoder) {
        self.encoder = encoder
        self.codingPath = []
        self.countOffset = encoder.data.count
        self.count = 0
        // will hold count
        encoder.data.append(Data([0, 0]))
    }

    func encodeNil() throws { try encoder.encodeNil() }
    func encode(_ value: Bool) throws { count += 1; try encoder.encode(value) }
    func encode(_ value: Int) throws { count += 1; try encoder.encode(value) }
    func encode(_ value: Int8) throws { count += 1; try encoder.encode(value) }
    func encode(_ value: Int16) throws { count += 1; try encoder.encode(value) }
    func encode(_ value: Int32) throws { count += 1; try encoder.encode(value) }
    func encode(_ value: Int64) throws { count += 1; try encoder.encode(value) }
    func encode(_ value: UInt) throws { count += 1; try encoder.encode(value) }
    func encode(_ value: UInt8) throws { count += 1; try encoder.encode(value) }
    func encode(_ value: UInt16) throws { count += 1; try encoder.encode(value) }
    func encode(_ value: UInt32) throws { count += 1; try encoder.encode(value) }
    func encode(_ value: UInt64) throws { count += 1; try encoder.encode(value) }
    func encode(_ value: Float) throws { count += 1; try encoder.encode(value) }
    func encode(_ value: Double) throws { count += 1; try encoder.encode(value) }
    func encode(_ value: String) throws { count += 1; try encoder.encode(value) }
    func encode<T>(_ value: T) throws where T : Encodable { count += 1; return try encoder.encode(value) }
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type)
        -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey { return encoder.container(keyedBy: NestedKey.self) }
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer { return encoder.unkeyedContainer() }
    func superEncoder() -> Encoder { return encoder }

    deinit {
        let size = numericCast(count) as Int16
        var data = Data([0, 0])
        data.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<Int16>) in
            pointer.pointee = size.bigEndian
        }
        encoder.data.replaceSubrange(countOffset..<countOffset + 2, with: data)
    }
}
