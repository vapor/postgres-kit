import Bits
import Foundation

/// Non-encoder wrapper for `_PostgreSQLMessageEncoder`.
final class PostgreSQLMessageEncoder {
    /// Create a new `PostgreSQLMessageEncoder`
    init() {}

    /// Encodes a `PostgreSQLMessage` to `Data`.
    func encode(_ message: PostgreSQLMessage) throws -> Data {
        let encoder = _PostgreSQLMessageEncoder()
        let identifier: Byte?
        switch message {
        case .startupMessage(let message):
            identifier = nil
            try message.encode(to: encoder)
        case .query(let query):
            identifier = .Q
            try query.encode(to: encoder)
        default: fatalError("Unsupported encodable type: \(type(of: message))")
        }
        encoder.updateSize()
        if let prefix = identifier {
            return [prefix] + encoder.data
        } else {
            return encoder.data
        }
    }
}

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
        try value.encode(to: self)
    }

    // Unsupported

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey { fatalError("Unsupported type: keyed container") }
    func unkeyedContainer() -> UnkeyedEncodingContainer { fatalError("Unsupported type: unkeyed container") }
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
