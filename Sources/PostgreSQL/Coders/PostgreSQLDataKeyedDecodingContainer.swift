/// Internal `KeyedDecodingContainerProtocol` for `PostgreSQLDataDecoder`
final class PostgreSQLDataKeyedDecodingContainer<K>: KeyedDecodingContainerProtocol
    where K: CodingKey 
{
    /// See `KeyedDecodingContainerProtocol.allKeys`
    var allKeys: [K]

    /// See `KeyedDecodingContainerProtocol.codingPath`
    var codingPath: [CodingKey]

    /// Data being encoded.
    let partialData: PartialPostgreSQLData

    /// Creates a new internal `PostgreSQLDataKeyedDecodingContainer`.
    init(partialData: PartialPostgreSQLData, at path: [CodingKey]) {
        self.codingPath = path
        self.partialData = partialData
        switch partialData.data {
        case .dictionary(let dict): allKeys = dict.keys.flatMap { Key(stringValue: $0) }
        default: allKeys = []
        }
    }

    /// See `KeyedDecodingContainerProtocol.contains`
    func contains(_ key: K) -> Bool {
        return allKeys.contains { key.stringValue == $0.stringValue }
    }

    /// See `KeyedDecodingContainerProtocol.decodeNil`
    func decodeNil(forKey key: K) throws -> Bool {
        return partialData.get(at: codingPath + [key]) == nil
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        switch try partialData.requireGet(at: codingPath + [key]) {
        case .bool(let value): return value
        default: throw DecodingError.typeMismatch(type, .init(codingPath: codingPath + [key], debugDescription: ""))
        }
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        switch try partialData.requireGet(at: codingPath + [key]) {
        case .int64(let value):
            guard MemoryLayout<Int>.size == 8 else {
                throw DecodingError.typeMismatch(Int.self, .init(codingPath: codingPath + [key], debugDescription: ""))
            }
            return Int(value)
        case .int32(let value):
            guard MemoryLayout<Int>.size == 4 else {
                throw DecodingError.typeMismatch(Int.self, .init(codingPath: codingPath + [key], debugDescription: ""))
            }
            return Int(value)
        default: throw DecodingError.typeMismatch(type, .init(codingPath: codingPath + [key], debugDescription: ""))
        }
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        switch try partialData.requireGet(at: codingPath + [key]) {
        case .int8(let value): return value
        default: throw DecodingError.typeMismatch(type, .init(codingPath: codingPath + [key], debugDescription: ""))
        }
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        switch try partialData.requireGet(at: codingPath + [key]) {
        case .int16(let value): return value
        default: throw DecodingError.typeMismatch(type, .init(codingPath: codingPath + [key], debugDescription: ""))
        }
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        switch try partialData.requireGet(at: codingPath + [key]) {
        case .int32(let value): return value
        default: throw DecodingError.typeMismatch(type, .init(codingPath: codingPath + [key], debugDescription: ""))
        }
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        switch try partialData.requireGet(at: codingPath + [key]) {
        case .int64(let value): return value
        default: throw DecodingError.typeMismatch(type, .init(codingPath: codingPath + [key], debugDescription: ""))
        }
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        let value = try decode(Int.self, forKey: key)
        guard value >= UInt.min else {
            throw PostgreSQLError(identifier: "uint", reason: "Int value \(value) too small to store in UInt.")
        }
        return UInt(value)
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        let value = try decode(Int8.self, forKey: key)
        guard value >= UInt8.min else {
            throw PostgreSQLError(identifier: "uint", reason: "Int8 value \(value) too small to store in UInt8.")
        }
        return UInt8(value)
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        let value = try decode(Int16.self, forKey: key)
        guard value >= UInt16.min else {
            throw PostgreSQLError(identifier: "uint", reason: "Int16 value \(value) too small to store in UInt16.")
        }
        return UInt16(value)
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        let value = try decode(Int32.self, forKey: key)
        guard value >= UInt32.min else {
            throw PostgreSQLError(identifier: "uint", reason: "Int32 value \(value) too small to store in UInt32.")
        }
        return UInt32(value)
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        let value = try decode(Int64.self, forKey: key)
        guard value >= UInt64.min else {
            throw PostgreSQLError(identifier: "uint", reason: "Int64 value \(value) too small to store in UInt64.")
        }
        return UInt64(value)
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        switch try partialData.requireGet(at: codingPath + [key]) {
        case .float(let value): return value
        default: throw DecodingError.typeMismatch(type, .init(codingPath: codingPath + [key], debugDescription: ""))
        }
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        switch try partialData.requireGet(at: codingPath + [key]) {
        case .double(let value): return value
        default: throw DecodingError.typeMismatch(type, .init(codingPath: codingPath + [key], debugDescription: ""))
        }
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: String.Type, forKey key: K) throws -> String {
        switch try partialData.requireGet(at: codingPath + [key]) {
        case .string(let value): return value
        default: throw DecodingError.typeMismatch(type, .init(codingPath: codingPath + [key], debugDescription: ""))
        }
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        let decoder = _PostgreSQLDataDecoder(partialData: partialData, at: codingPath + [key])
        return try T(from: decoder)
    }

    /// See `KeyedDecodingContainerProtocol.nestedContainer`
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = PostgreSQLDataKeyedDecodingContainer<NestedKey>(partialData: partialData, at: codingPath + [key])
        return .init(container)
    }

    /// See `KeyedDecodingContainerProtocol.nestedUnkeyedContainer`
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        fatalError("Not yet supported")
    }

    /// See `KeyedDecodingContainerProtocol.superDecoder`
    func superDecoder() throws -> Decoder {
        return _PostgreSQLDataDecoder(partialData: partialData, at: codingPath)
    }

    /// See `KeyedDecodingContainerProtocol.superDecoder`
    func superDecoder(forKey key: K) throws -> Decoder {
        return _PostgreSQLDataDecoder(partialData: partialData, at: codingPath + [key])
    }
}
