/// Converts `Encodable` objects to `PostgreSQLData`.
///
///     let data = try PostgreSQLDataEncoder().encode("hello")
///     print(data) // PostgreSQLData
///
public struct PostgreSQLDataEncoder {
    /// Creates a new `PostgreSQLDataEncoder`.
    public init() { }

    /// Encodes the supplied `Encodable` object to `PostgreSQLData`.
    ///
    ///     let data = try PostgreSQLDataEncoder().encode("hello")
    ///     print(data) // PostgreSQLData
    ///
    /// - parameters:
    ///     - encodable: `Encodable` object to encode.
    /// - returns: Encoded `PostgreSQLData`.
    public func encode(_ encodable: Encodable) throws -> PostgreSQLData {
        if let convertible = encodable as? PostgreSQLDataConvertible {
            return try convertible.convertToPostgreSQLData()
        }
        
        do {
            let encoder = _Encoder()
            try encodable.encode(to: encoder)
            if let data = encoder.data {
                return data
            } else {
                let type = encoder.array.first?.type ?? .null
                // encode array
                var data = Data()
                data += Data.of(Int32(1).bigEndian) // non-null
                data += Data.of(Int32(0).bigEndian) // b
                data += Data.of(type.raw.bigEndian)
                data += Data.of(Int32(encoder.array.count).bigEndian) // length
                data += Data.of(Int32(1).bigEndian) // dimensions
                
                for element in encoder.array {
                    switch element.storage {
                    case .binary(let value):
                        data += Data.of(Int32(value.count).bigEndian)
                        data += value
                    default: data += Data.of(Int32(0).bigEndian)
                    }
                }
                return PostgreSQLData(type.arrayType ?? .null, binary: data)
            }
        } catch is _KeyedError {
            struct AnyEncodable: Encodable {
                var encodable: Encodable
                init(_ encodable: Encodable) {
                    self.encodable = encodable
                }
                
                func encode(to encoder: Encoder) throws {
                    try encodable.encode(to: encoder)
                }
            }
            return try PostgreSQLData(.jsonb, binary: [0x01] + JSONEncoder().encode(AnyEncodable(encodable)))
        }
    }


    // MARK: Private
    
    private final class _Encoder: Encoder {
        let codingPath: [CodingKey] = []
        let userInfo: [CodingUserInfoKey: Any] = [:]
        var data: PostgreSQLData?
        var array: [PostgreSQLData]
        
        init() {
            self.data = nil
            self.array = []
        }
        
        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            return .init(_KeyedEncodingContainer(encoder: self))
        }
        
        func unkeyedContainer() -> UnkeyedEncodingContainer {
            return _UnkeyedEncodingContainer(encoder: self)
        }
        
        func singleValueContainer() -> SingleValueEncodingContainer {
            return _SingleValueEncodingContainer(encoder: self)
        }
    }
    
    static let _true = Data([0x01])
    static let _false = Data([0x00])
    
    private struct _SingleValueEncodingContainer: SingleValueEncodingContainer {
        let codingPath: [CodingKey] = []
        let encoder: _Encoder
        
        init(encoder: _Encoder) {
            self.encoder = encoder
        }
        
        mutating func encodeNil() throws {
            encoder.data = .null
        }

        mutating func encode<T>(_ value: T) throws where T : Encodable {
            if let convertible = value as? PostgreSQLDataConvertible {
                encoder.data = try convertible.convertToPostgreSQLData()
                return
            }
            try value.encode(to: encoder)
        }
    }
    
    private struct _UnkeyedEncodingContainer: UnkeyedEncodingContainer {
        let codingPath: [CodingKey] = []
        let encoder: _Encoder
        var count: Int
        init(encoder: _Encoder) {
            self.encoder = encoder
            self.count = 0
        }
        
        mutating func encodeNil() throws {
            encoder.array.append(.null)
        }
        
        mutating func encode<T>(_ value: T) throws where T : Encodable {
            if let convertible = value as? PostgreSQLDataConvertible {
                try encoder.array.append(convertible.convertToPostgreSQLData())
            } else {
                try value.encode(to: encoder)
            }
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return .init(_KeyedEncodingContainer<NestedKey>(encoder: encoder))
        }
        
        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            return _UnkeyedEncodingContainer(encoder: encoder)
        }
        
        mutating func superEncoder() -> Encoder {
            return encoder
        }
    }
    
    private struct _KeyedError: Error { }
    
    private struct _KeyedEncodingContainer<Key>: KeyedEncodingContainerProtocol where Key: CodingKey {
        let codingPath: [CodingKey] = []
        let encoder: _Encoder
        init(encoder: _Encoder) {
            self.encoder = encoder
        }
        
        mutating func encodeNil(forKey key: Key) throws {
            throw _KeyedError()
        }
        
        mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            throw _KeyedError()
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            return .init(_KeyedEncodingContainer<NestedKey>(encoder: encoder))
        }
        
        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return _UnkeyedEncodingContainer(encoder: encoder)
        }
        
        mutating func superEncoder() -> Encoder {
            return encoder
        }
        
        mutating func superEncoder(forKey key: Key) -> Encoder {
            return encoder
        }
    }
}
