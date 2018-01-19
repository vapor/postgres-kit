/// Internal `KeyedEncodingContainerProtocol` for `CodableDataEncoder`.
internal final class CodableDataKeyedEncodingContainer<K>: KeyedEncodingContainerProtocol
    where K: CodingKey
{
    /// See `KeyedEncodingContainerProtocol.codingPath`
    var codingPath: [CodingKey]

    /// Data being encoded.
    let partialData: PartialCodableData

    /// Creates a new `CodableDataKeyedEncodingContainer`
    init(partialData: PartialCodableData, at path: [CodingKey]) {
        self.codingPath = path
        self.partialData = partialData
    }

    /// See `KeyedEncodingContainerProtocol.encodeNil`
    func encodeNil(forKey key: K) throws {
        partialData.set(.null, at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: Bool, forKey key: K) throws {
        partialData.set(.bool(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: Int, forKey key: K) throws {
        partialData.set(.int(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: Int8, forKey key: K) throws {
        partialData.set(.int8(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: Int16, forKey key: K) throws {
        partialData.set(.int16(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: Int32, forKey key: K) throws {
        partialData.set(.int32(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: Int64, forKey key: K) throws {
        partialData.set(.int64(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: UInt, forKey key: K) throws {
        partialData.set(.uint(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: UInt8, forKey key: K) throws {
        partialData.set(.uint8(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: UInt16, forKey key: K) throws {
        partialData.set(.uint16(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: UInt32, forKey key: K) throws {
        partialData.set(.uint32(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: UInt64, forKey key: K) throws {
        partialData.set(.uint64(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: Float, forKey key: K) throws {
        partialData.set(.float(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: Double, forKey key: K) throws {
        partialData.set(.double(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: String, forKey key: K) throws {
        partialData.set(.string(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        try partialData.set(.encodable(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.nestedContainer`
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey>
        where NestedKey: CodingKey
    {
        let container = CodableDataKeyedEncodingContainer<NestedKey>(partialData: partialData, at: codingPath + [key])
        return .init(container)
    }

    /// See `KeyedEncodingContainerProtocol.nestedUnkeyedContainer`
    func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        return CodableDataUnkeyedEncodingContainer(partialData: partialData, at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.superEncoder`
    func superEncoder() -> Encoder {
        return _CodableDataEncoder(partialData: partialData, at: codingPath)
    }

    /// See `KeyedEncodingContainerProtocol.superEncoder`
    func superEncoder(forKey key: K) -> Encoder {
        return _CodableDataEncoder(partialData: partialData, at: codingPath + [key])
    }
}

