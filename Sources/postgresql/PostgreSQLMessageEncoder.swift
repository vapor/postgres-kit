import Foundation

/// Non-encoder wrapper for `_PostgreSQLMessageEncoder`.
final class PostgreSQLMessageEncoder {
    /// Create a new `PostgreSQLMessageEncoder`
    init() {}

    /// Encodes a `PostgreSQLMessage` to `Data`.
    func encode<Message>(_ message: Message) throws -> Data where Message: PostgreSQLMessage {
        let encoder = _PostgreSQLMessageEncoder()
        try message.encode(to: encoder)
        encoder.updateSize()
        if let identifier = Message.identifier {
            return [identifier] + encoder.data
        } else {
            return encoder.data
        }
    }
}

// MARK: Encoder / Single

internal final class _PostgreSQLMessageEncoder: Encoder, SingleValueEncodingContainer {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    var data: Data

    init() {
        self.codingPath = []
        self.userInfo = [:]
        self.data = Data([0, 0, 0, 0])
    }

    func updateSize() {
        let size = numericCast(data.count - 4) as Int32
        data.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<Int32>) in
            pointer.pointee = size.bigEndian
        }
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = PostgreSQLMessageKeyedEncodingContainer<Key>(encoder: self)
        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return PostgreSQLMessageUnkeyedEncodingContainer(encoder: self)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }

    func encode(_ value: String) throws {
        // kafka style string
//        let stringData = Data(value.utf8)
//
//        guard stringData.count < numericCast(Int16.max) else {
//            throw UnsupportedStringLength()
//        }
//
//        try encode(numericCast(stringData.count) as Int16)
//        self.data.append(stringData)
        // c style string
        let stringData = Data(value.utf8)
        self.data.append(stringData + [0])
    }

    func encode(_ value: Int8) throws {
        self.data.append(numericCast(value))
    }

    func encode(_ value: Int16) throws {
        var value = value.bigEndian
        withUnsafeBytes(of: &value) { buffer in
            let buffer = buffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
            self.data.append(buffer, count: 2)
        }
    }

    func encode(_ value: Int32) throws {
        var value = value.bigEndian
        withUnsafeBytes(of: &value) { buffer in
            let buffer = buffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
            self.data.append(buffer, count: 4)
        }
    }

    func encode(_ value: Int64) throws {
        var value = value.bigEndian
        withUnsafeBytes(of: &value) { buffer in
            let buffer = buffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
            self.data.append(buffer, count: 8)
        }
    }

    func encode<T>(_ value: T) throws where T : Encodable {
        try value.encode(to: self)
    }

    // Unsupported

    func encode(_ value: Int) throws { fatalError("Unsupported type: \(type(of: value))") }
    func encode(_ value: UInt) throws { fatalError("Unsupported type: \(type(of: value))") }
    func encode(_ value: UInt8) throws { fatalError("Unsupported type: \(type(of: value))") }
    func encode(_ value: UInt16) throws { fatalError("Unsupported type: \(type(of: value))") }
    func encode(_ value: UInt32) throws { fatalError("Unsupported type: \(type(of: value))") }
    func encode(_ value: UInt64) throws { fatalError("Unsupported type: \(type(of: value))") }
    func encode(_ value: Float) throws { fatalError("Unsupported type: \(type(of: value))") }
    func encode(_ value: Double) throws { fatalError("Unsupported type: \(type(of: value))") }
    func encode(_ value: Bool) throws { fatalError("Unsupported type: \(type(of: value))") }
    func encodeNil() throws { fatalError("Unsupported type: nil") }
}

// MARK: Keyed

internal struct PostgreSQLMessageKeyedEncodingContainer<K>: KeyedEncodingContainerProtocol where K: CodingKey {
    var count = 0
    typealias Key = K

    var codingPath: [CodingKey]
    let encoder: _PostgreSQLMessageEncoder

    init(encoder: _PostgreSQLMessageEncoder) {
        self.encoder = encoder
        self.codingPath = []
    }

    mutating func encode(_ value: Int, forKey key: K) throws { try encoder.encode(value) }
    mutating func encode(_ value: Int8, forKey key: K) throws { try encoder.encode(value) }
    mutating func encode(_ value: Int16, forKey key: K) throws { try encoder.encode(value) }
    mutating func encode(_ value: Int32, forKey key: K) throws { try encoder.encode(value) }
    mutating func encode(_ value: Int64, forKey key: K) throws { try encoder.encode(value) }
    mutating func encode(_ value: UInt, forKey key: K) throws { try encoder.encode(value) }
    mutating func encode(_ value: UInt8, forKey key: K) throws { try encoder.encode(value) }
    mutating func encode(_ value: UInt16, forKey key: K) throws { try encoder.encode(value) }
    mutating func encode(_ value: UInt32, forKey key: K) throws { try encoder.encode(value) }
    mutating func encode(_ value: UInt64, forKey key: K) throws { try encoder.encode(value) }
    mutating func encode(_ value: Float, forKey key: K) throws { try encoder.encode(value) }
    mutating func encode(_ value: Double, forKey key: K) throws { try encoder.encode(value) }
    mutating func encode(_ value: String, forKey key: K) throws { try encoder.encode(value) }
    mutating func encode<T>(_ value: T, forKey key: K) throws where T : Encodable { try value.encode(to: encoder)}
    mutating func encode(_ value: Bool, forKey key: K) throws { try encoder.encode(value) }
    mutating func encodeNil(forKey key: K) throws { try encoder.encodeNil() }
    mutating func superEncoder() -> Encoder { return encoder }
    mutating func superEncoder(forKey key: K) -> Encoder { return encoder }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = PostgreSQLMessageKeyedEncodingContainer<NestedKey>(encoder: encoder)
        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        return PostgreSQLMessageUnkeyedEncodingContainer(encoder: encoder)
    }
}

// MARK: Unkeyed

internal struct PostgreSQLMessageUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    var codingPath: [CodingKey]
    var count: Int
    let encoder: _PostgreSQLMessageEncoder

    init(encoder: _PostgreSQLMessageEncoder) {
        self.encoder = encoder
        self.codingPath = []
        self.count = 0
    }

    mutating func encode(_ value: Int) throws { try encoder.encode(value) }
    mutating func encode(_ value: Int8) throws { try encoder.encode(value) }
    mutating func encode(_ value: Int16) throws { try encoder.encode(value) }
    mutating func encode(_ value: Int32) throws { try encoder.encode(value) }
    mutating func encode(_ value: Int64) throws { try encoder.encode(value) }
    mutating func encode(_ value: UInt) throws { try encoder.encode(value) }
    mutating func encode(_ value: UInt8) throws { try encoder.encode(value) }
    mutating func encode(_ value: UInt16) throws { try encoder.encode(value) }
    mutating func encode(_ value: UInt32) throws { try encoder.encode(value) }
    mutating func encode(_ value: UInt64) throws { try encoder.encode(value) }
    mutating func encode(_ value: Float) throws { try encoder.encode(value) }
    mutating func encode(_ value: Double) throws { try encoder.encode(value) }
    mutating func encode(_ value: String) throws { try encoder.encode(value) }
    mutating func encode<T>(_ value: T) throws where T : Encodable { try value.encode(to: encoder)}
    mutating func encode(_ value: Bool) throws { try encoder.encode(value) }
    mutating func encodeNil() throws { try encoder.encodeNil() }
    mutating func superEncoder() -> Encoder { return encoder }
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer { return self }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = PostgreSQLMessageKeyedEncodingContainer<NestedKey>(encoder: encoder)
        return KeyedEncodingContainer(container)
    }
}
