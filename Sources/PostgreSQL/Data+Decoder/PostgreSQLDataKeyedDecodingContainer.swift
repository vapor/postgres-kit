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
        return try partialData.requireBool(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        return try partialData.requireFixedWidthItenger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        return try partialData.requireFixedWidthItenger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        return try partialData.requireFixedWidthItenger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        return try partialData.requireFixedWidthItenger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        return try partialData.requireFixedWidthItenger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        return try partialData.requireFixedWidthItenger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        return try partialData.requireFixedWidthItenger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        return try partialData.requireFixedWidthItenger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        return try partialData.requireFixedWidthItenger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        return try partialData.requireFixedWidthItenger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        return try partialData.requireFloatingPoint(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        return try partialData.requireFloatingPoint(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: String.Type, forKey key: K) throws -> String {
        return try partialData.requireString(at: codingPath + [key])
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
