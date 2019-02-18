/// Converts `Encodable` objects to `PostgreSQLData`.
///
///     let data = try PostgreSQLDataEncoder().encode("hello")
///     print(data) // PostgreSQLData
///
struct PostgreSQLDataEncoder {
    /// Creates a new `PostgreSQLDataEncoder`.
    init() { }

    /// Encodes the supplied `Encodable` object to `PostgreSQLData`.
    ///
    ///     let data = try PostgreSQLDataEncoder().encode("hello")
    ///     print(data) // PostgreSQLData
    ///
    /// - parameters:
    ///     - encodable: `Encodable` object to encode.
    /// - returns: Encoded `PostgreSQLData`.
    func encode(_ encodable: Encodable) throws -> PostgreSQLData {
        if let convertible = encodable as? PostgreSQLDataConvertible {
            return try convertible.convertToPostgreSQLData()
        }
        
        let encoder = _Encoder()
        try encodable.encode(to: encoder)
        if encoder.keyedEncoding {
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
        } else if let data = encoder.data {
            return data
        } else {
            let type: PostgreSQLDataFormat
            if let present = encoder.array.first?.type {
                type = present
            } else if
                let array = Swift.type(of: encodable) as? AnyArray.Type,
                let psql = array.anyElementType as? PostgreSQLDataTypeStaticRepresentable.Type
            {
                if let format = psql.postgreSQLDataType.dataFormat {
                    type = format
                } else {
                    WARNING("Could not determine PostgreSQL array data type: \(psql.postgreSQLDataType)")
                    type = .null
                }
            } else {
                WARNING("Could not determine PostgreSQL array data type: \(Swift.type(of: encodable))")
                type = .null
            }
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
    }


    // MARK: Private
    
    private final class _Encoder: Encoder {
        let codingPath: [CodingKey] = []
        let userInfo: [CodingUserInfoKey: Any] = [:]
        var data: PostgreSQLData?
        var array: [PostgreSQLData]
        var keyedEncoding: Bool
        
        init() {
            self.data = nil
            self.array = []
            self.keyedEncoding = false
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
            let data: PostgreSQLData
            if let convertible = value as? PostgreSQLDataConvertible {
                data = try convertible.convertToPostgreSQLData()
            } else {
                data = try PostgreSQLDataEncoder().encode(value)
            }
            encoder.array.append(data)
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
    
    private struct _KeyedEncodingContainer<Key>: KeyedEncodingContainerProtocol where Key: CodingKey {
        let codingPath: [CodingKey] = []
        let encoder: _Encoder
        init(encoder: _Encoder) {
            self.encoder = encoder
            encoder.keyedEncoding = true
        }
        
        mutating func encodeNil(forKey key: Key) throws {
            return
        }
        
        mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            return
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

protocol AnyArray {
    static var anyElementType: Any.Type { get }
}

extension Array: AnyArray {
    static var anyElementType: Any.Type {
        return Element.self
    }
}
