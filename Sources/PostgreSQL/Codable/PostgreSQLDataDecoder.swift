public struct PostgreSQLDataDecoder {
    /// Creates a new `PostgreSQLDataDecoder`.
    public init() {}
    
    public func decode<D>(_ type: D.Type, from data: PostgreSQLData) throws -> D where D: Decodable {
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
        
        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
            let json: Data
            switch data.type {
            case .jsonb:
                switch data.storage {
                case .binary(let data):
                    assert(data[data.startIndex] == 0x01, "invalid JSONB data format")
                    json = data.advanced(by: 1)
                default: throw DecodingError.typeMismatch(Data.self, .init(codingPath: codingPath, debugDescription: "Could not decode keyed data from \(data.type): \(data)."))
                }
            default: throw DecodingError.typeMismatch(Data.self, .init(codingPath: codingPath, debugDescription: "Could not decode keyed data from \(data.type): \(data)."))
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
        
        func typeMismatch<T>(_ type: T.Type) -> Error {
            return DecodingError.typeMismatch(type, .init(codingPath: codingPath, debugDescription: "Could not decode \(type) from \(data.type): \(data)"))
        }
        
        func valueNotFound<T>(_ type: T.Type) -> Error {
            return DecodingError.valueNotFound(type, .init(codingPath: codingPath, debugDescription: "Could not decode \(type) from null."))
        }
        
        public func decodeNil() -> Bool {
            switch data.storage {
            case .null: return true
            default: return false
            }
        }
        
        public func decode(_ type: Bool.Type) throws -> Bool {
            switch data.storage {
            case .text(let value):
                guard value.count == 1 else {
                    throw typeMismatch(type)
                }
                switch value[value.startIndex] {
                case "t": return true
                case "f": return false
                default: throw typeMismatch(type)
                }
            case .binary(let value):
                guard value.count == 1 else {
                    throw typeMismatch(type)
                }
                switch value[0] {
                case 1: return true
                case 0: return false
                default: throw typeMismatch(type)
                }
            case .null: throw valueNotFound(type)
            }
        }
        
        public func decode(_ type: String.Type) throws -> String {
            switch data.storage {
            case .text(let string): return string
            case .binary(let value):
                switch data.type {
                case .text, .name, .varchar, .bpchar:
                    guard let string = String(data: value, encoding: .utf8) else {
                        throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Non-UTF8 String."))
                    }
                    return string
                case .point: return try decode(PostgreSQLPoint.self).description
                case .uuid: return try decode(UUID.self).uuidString
                case .numeric:
                    /// Represents the meta information preceeding a numeric value.
                    /// - note: all values must be accessed adding `.bigEndian`
                    struct PostgreSQLNumericMetadata {
                        /// The number of digits after this metadata
                        var ndigits: Int16
                        /// How many of the digits are before the decimal point (always add 1)
                        var weight: Int16
                        /// If 1, this number is negative. Otherwise, positive.
                        var sign: Int16
                        /// The number of sig digits after the decimal place (get rid of trailing 0s)
                        var dscale: Int16
                    }
                    
                    /// create mutable value since we will be using `.extract` which advances the buffer's view
                    var value = value
                    
                    /// grab the numeric metadata from the beginning of the array
                    let metadata = value.extract(PostgreSQLNumericMetadata.self)
                    
                    var integer = ""
                    var fractional = ""
                    for offset in 0..<metadata.ndigits.bigEndian {
                        /// extract current char and advance memory
                        let char = value.extract(Int16.self).bigEndian
                        
                        /// conver the current char to its string form
                        let string: String
                        if char == 0 {
                            /// 0 means 4 zeros
                            string = "0000"
                        } else {
                            string = char.description
                        }
                        
                        /// depending on our offset, append the string to before or after the decimal point
                        if offset < metadata.weight.bigEndian + 1 {
                            integer += string
                        } else {
                            // Leading zeros matter with fractional
                            fractional += fractional.count == 0 ? String(repeating: "0", count: 4 - string.count) + string : string
                        }
                    }
                    
                    /// use the dscale to remove extraneous zeroes at the end of the fractional part
                    let lastSignificantIndex = fractional.index(fractional.startIndex, offsetBy: Int(metadata.dscale.bigEndian))
                    fractional = String(fractional[..<lastSignificantIndex])
                    
                    /// determine whether fraction is empty and dynamically add `.`
                    let numeric: String
                    if fractional != "" {
                        numeric = integer + "." + fractional
                    } else {
                        numeric = integer
                    }
                    
                    /// use sign to determine adding a leading `-`
                    if metadata.sign.bigEndian == 1 {
                        return "-" + numeric
                    } else {
                        return numeric
                    }
                default: throw typeMismatch(type)
                }
            case .null: throw valueNotFound(type)
            }
        }
        
        public func decode(_ type: Double.Type) throws -> Double {
            fatalError()
        }
        
        public func decode(_ type: Float.Type) throws -> Float {
            fatalError()
        }
        
        public func decode(_ type: Int.Type) throws -> Int {
            fatalError()
        }
        
        public func decode(_ type: Int8.Type) throws -> Int8 {
            fatalError()
        }
        
        public func decode(_ type: Int16.Type) throws -> Int16 {
            fatalError()
        }
        
        public func decode(_ type: Int32.Type) throws -> Int32 {
            fatalError()
        }
        
        public func decode(_ type: Int64.Type) throws -> Int64 {
            fatalError()
        }
        
        public func decode(_ type: UInt.Type) throws -> UInt {
            fatalError()
        }
        
        public func decode(_ type: UInt8.Type) throws -> UInt8 {
            fatalError()
        }
        
        public func decode(_ type: UInt16.Type) throws -> UInt16 {
            fatalError()
        }
        
        public func decode(_ type: UInt32.Type) throws -> UInt32 {
            fatalError()
        }
        
        public func decode(_ type: UInt64.Type) throws -> UInt64 {
            fatalError()
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            guard let convertible = type as? PostgreSQLDataConvertible.Type else {
                return try T(from: _Decoder(data: data))
            }
            return try convertible.convertFromPostgreSQLData(data) as! T
        }
    }
}
