/// Internal `KeyedDecodingContainerProtocol` for `CodableDataDecoder`
final class CodableDataKeyedDecodingContainer<K>: KeyedDecodingContainerProtocol
    where K: CodingKey
{
    /// See `KeyedDecodingContainerProtocol.allKeys`
    var allKeys: [K]

    /// See `KeyedDecodingContainerProtocol.codingPath`
    var codingPath: [CodingKey]

    /// Data being encoded.
    let partialData: PartialCodableData

    /// Creates a new internal `CodableDataKeyedDecodingContainer`.
    init(partialData: PartialCodableData, at path: [CodingKey]) {
        self.codingPath = path
        self.partialData = partialData
        switch partialData.get(at: path) {
        case .some(let data):
            switch data {
            case .dictionary(let value): allKeys = value.keys.flatMap { Key(stringValue: $0) }
            default: allKeys = []
            }
        default: allKeys = []
        }
    }

    /// See `KeyedDecodingContainerProtocol.contains`
    func contains(_ key: K) -> Bool {
        return allKeys.contains { key.stringValue == $0.stringValue }
    }

    /// See `KeyedDecodingContainerProtocol.decodeNil`
    func decodeNil(forKey key: K) throws -> Bool {
        return partialData.decodeNil(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        return try partialData.decodeBool(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        return try partialData.decodeFloatingPoint(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        return try partialData.decodeFloatingPoint(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode(_ type: String.Type, forKey key: K) throws -> String {
        return try partialData.decodeString(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.decode`
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        return try partialData.decode(at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.nestedContainer`
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = CodableDataKeyedDecodingContainer<NestedKey>(partialData: partialData, at: codingPath + [key])
        return .init(container)
    }

    /// See `KeyedDecodingContainerProtocol.nestedUnkeyedContainer`
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        return CodableDataUnkeyedDecodingContainer(partialData: partialData, at: codingPath + [key])
    }

    /// See `KeyedDecodingContainerProtocol.superDecoder`
    func superDecoder() throws -> Decoder {
        return _CodableDataDecoder(partialData: partialData, at: codingPath)
    }

    /// See `KeyedDecodingContainerProtocol.superDecoder`
    func superDecoder(forKey key: K) throws -> Decoder {
        return _CodableDataDecoder(partialData: partialData, at: codingPath + [key])
    }
}

