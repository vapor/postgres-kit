/// Internal `UnkeyedEncodingContainer` for `CodableDataEncoder`.
internal final class CodableDataUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    /// See `UnkeyedEncodingContainer.count`
    var count: Int

    /// See `KeyedEncodingContainerProtocol.codingPath`
    var codingPath: [CodingKey]

    /// Data being encoded.
    let partialData: PartialCodableData

    /// Creates a coding key for the current index, then increments the count.
    var index: CodingKey {
        defer { count += 1 }
        return CodableDataArrayKey(count)
    }

    /// Creates a new `CodableDataKeyedEncodingContainer`
    init(partialData: PartialCodableData, at path: [CodingKey]) {
        self.codingPath = path
        self.partialData = partialData
        self.count = 0
    }

    /// See `UnkeyedEncodingContainer.encodeNil`
    func encodeNil() throws {
        partialData.set(.null, at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: Bool) throws {
        partialData.set(.bool(value), at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: Int) throws {
        partialData.set(.int(value), at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: Int8) throws {
        partialData.set(.int8(value), at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: Int16) throws {
        partialData.set(.int16(value), at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: Int32) throws {
        partialData.set(.int32(value), at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: Int64) throws {
        partialData.set(.int64(value), at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: UInt) throws {
        partialData.set(.uint(value), at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: UInt8) throws {
        partialData.set(.uint8(value), at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: UInt16) throws {
        partialData.set(.uint16(value), at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: UInt32) throws {
        partialData.set(.uint32(value), at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: UInt64) throws {
        partialData.set(.uint64(value), at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: Float) throws {
        partialData.set(.float(value), at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: Double) throws {
        partialData.set(.double(value), at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: String) throws {
        partialData.set(.string(value), at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode<T>(_ value: T) throws where T : Encodable {
        partialData.set(.encodable(value), at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.nestedContainer`
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey>
        where NestedKey: CodingKey
    {
        let container = CodableDataKeyedEncodingContainer<NestedKey>(partialData: partialData, at: codingPath + [index])
        return .init(container)
    }

    /// See `UnkeyedEncodingContainer.nestedUnkeyedContainer`
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return CodableDataUnkeyedEncodingContainer(partialData: partialData, at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.superEncoder`
    func superEncoder() -> Encoder {
        return _CodableDataEncoder(partialData: partialData, at: codingPath + [index])
    }
}

