public struct PostgreSQLDataDecoder {
    /// Creates a new `PostgreSQLDataDecoder`.
    public init() {}
    
    public func decode<D>(_ type: D.Type, from data: PostgreSQLData) throws -> D where D: Decodable {
        if let convertible = type as? PostgreSQLDataConvertible.Type {
            return try convertible.convertFromPostgreSQLData(data) as! D
        }
        return try D(from: _Decoder(data: data))
    }
    
    // MARK: Private
    
    private struct _Decoder: Decoder {
        let codingPath: [CodingKey] = []
        var userInfo: [CodingUserInfoKey: Any] = [:]
        let data: PostgreSQLData
        
        init(data: PostgreSQLData) {
            self.data = data
        }
        
        struct DecoderUnwrapper: Decodable {
            let decoder: Decoder
            init(from decoder: Decoder) throws {
                self.decoder = decoder
            }
        }
        
        struct JSON { }
        
        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
            let json: Data
            switch data.type {
            case .jsonb, .json:
                switch data.storage {
                case .binary(let data):
                    assert(data[data.startIndex] == 0x01, "invalid JSONB data format")
                    json = data.advanced(by: 1)
                case .text(let string): json = Data(string.utf8)
                default: throw PostgreSQLError.decode(JSON.self, from: data)
                }
            default: throw PostgreSQLError.decode(JSON.self, from: data)
            }
            let unwrapper = try JSONDecoder().decode(DecoderUnwrapper.self, from: json)
            return try unwrapper.decoder.container(keyedBy: Key.self)
        }
        
        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            struct ArrayMetadata {
                /// Unknown
                private let _b: Int32
                
                /// The big-endian array element type
                private let _type: Int32
                
                /// The big-endian length of the array
                private let _count: Int32
                
                /// The big-endian number of dimensions
                private let _dimensions: Int32
                
                /// Converts the raw array elemetn type to DataType
                var type: PostgreSQLDataType {
                    return .init(_type.bigEndian)
                }
                
                /// The length of the array
                var count: Int32 {
                    return _count.bigEndian
                }
                
                /// The  number of dimensions
                var dimensions: Int32 {
                    return _dimensions.bigEndian
                }
            }
            
            switch data.storage {
            case .binary(var value):
                /// Extract and convert each element.
                var array: [PostgreSQLData] = []
                
                let hasData = value.extract(Int32.self).bigEndian
                if hasData == 1 {
                    /// grab the array metadata from the beginning of the data
                    let metadata = value.extract(ArrayMetadata.self)
                    for _ in 0..<metadata.count {
                        let count = Int(value.extract(Int32.self).bigEndian)
                        let subValue = value.extract(count: count)
                        let psqlData = PostgreSQLData(metadata.type, binary: subValue)
                        array.append(psqlData)
                    }
                } else {
                    array = []
                }
                
                print(array)
                fatalError("Unimplemented.")
            default: fatalError()
            }
        }
        
        func singleValueContainer() throws -> SingleValueDecodingContainer {
            return _SingleValueDecodingContainer(data: data)
        }
    }
    
    private struct _SingleValueDecodingContainer: SingleValueDecodingContainer {
        let codingPath: [CodingKey] = []
        let data: PostgreSQLData
        
        init(data: PostgreSQLData) {
            self.data = data
        }
        
        public func decodeNil() -> Bool {
            switch data.storage {
            case .null: return true
            default: return false
            }
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            guard let convertible = type as? PostgreSQLDataConvertible.Type else {
                return try T(from: _Decoder(data: data))
            }
            return try convertible.convertFromPostgreSQLData(data) as! T
        }
    }
}
