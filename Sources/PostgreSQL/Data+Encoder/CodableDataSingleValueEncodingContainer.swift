/// Internal `SingleValueEncodingContainer` for `CodableDataEncoder`.
internal final class CodableDataSingleValueEncodingContainer: SingleValueEncodingContainer {
    /// See `KeyedEncodingContainerProtocol.codingPath`
    var codingPath: [CodingKey]

    /// Data being encoded.
    let partialData: PartialCodableData

    /// Creates a new `CodableDataKeyedEncodingContainer`
    init(partialData: PartialCodableData, at path: [CodingKey]) {
        self.codingPath = path
        self.partialData = partialData
    }

    /// See `SingleValueEncodingContainer.encodeNil`
    func encodeNil() throws {
        partialData.set(.null, at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: Bool) throws {
        partialData.set(.bool(value), at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: Int) throws {
        partialData.set(.int(value), at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: Int8) throws {
        partialData.set(.int8(value), at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: Int16) throws {
        partialData.set(.int16(value), at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: Int32) throws {
        partialData.set(.int32(value), at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: Int64) throws {
        partialData.set(.int64(value), at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: UInt) throws {
        partialData.set(.uint(value), at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: UInt8) throws {
        partialData.set(.uint8(value), at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: UInt16) throws {
        partialData.set(.uint16(value), at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: UInt32) throws {
        partialData.set(.uint32(value), at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: UInt64) throws {
        partialData.set(.uint64(value), at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: Float) throws {
        partialData.set(.float(value), at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: Double) throws {
        partialData.set(.double(value), at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: String) throws {
        partialData.set(.string(value), at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode<T>(_ value: T) throws where T : Encodable {
        partialData.set(.encodable(value), at: codingPath)
    }

    /// See `SingleValueEncodingContainer.nestedContainer`
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey>
        where NestedKey: CodingKey
    {
        let container = CodableDataKeyedEncodingContainer<NestedKey>(partialData: partialData, at: codingPath)
        return .init(container)
    }

    /// See `SingleValueEncodingContainer.nestedSingleValueContainer`
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return CodableDataUnkeyedEncodingContainer(partialData: partialData, at: codingPath)
    }

    /// See `SingleValueEncodingContainer.superEncoder`
    func superEncoder() -> Encoder {
        return _CodableDataEncoder(partialData: partialData, at: codingPath)
    }
}

