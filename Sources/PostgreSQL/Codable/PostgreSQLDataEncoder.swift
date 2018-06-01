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
            guard let data = encoder.data else {
                fatalError()
            }
            return data
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
        
        init() {
            self.data = nil
        }
        
        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            return .init(_KeyedEncodingContainer())
        }
        
        func unkeyedContainer() -> UnkeyedEncodingContainer {
            fatalError()
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
            } else {
                try value.encode(to: encoder)
            }
        }
    }
    
    private struct _KeyedError: Error { }
    
    private struct _KeyedEncodingContainer<Key>: KeyedEncodingContainerProtocol where Key: CodingKey {
        let codingPath: [CodingKey] = []
        init() { }
        
        mutating func encodeNil(forKey key: Key) throws {
            throw _KeyedError()
        }
        
        mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            throw _KeyedError()
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            return .init(_KeyedEncodingContainer<NestedKey>())
        }
        
        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            fatalError()
        }
        
        mutating func superEncoder() -> Encoder {
            fatalError()
        }
        
        mutating func superEncoder(forKey key: Key) -> Encoder {
            fatalError()
        }
    }
}
