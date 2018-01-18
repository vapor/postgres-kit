/// Internal `SingleValueEncodingContainer` for `PostgreSQLDataEncoder`.
internal final class PostgreSQLDataSingleValueEncodingContainer: SingleValueEncodingContainer {
    /// See `KeyedEncodingContainerProtocol.codingPath`
    var codingPath: [CodingKey]

    /// Data being encoded.
    let partialData: PartialPostgreSQLData

    /// Creates a new `PostgreSQLDataKeyedEncodingContainer`
    init(partialData: PartialPostgreSQLData, at path: [CodingKey]) {
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
        try partialData.setFixedWidthInteger(value, at: codingPath)
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
        try partialData.setFixedWidthInteger(value, at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: UInt8) throws {
        try partialData.setFixedWidthInteger(value, at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: UInt16) throws {
        try partialData.setFixedWidthInteger(value, at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: UInt32) throws {
        try partialData.setFixedWidthInteger(value, at: codingPath)
    }

    /// See `SingleValueEncodingContainer.encode`
    func encode(_ value: UInt64) throws {
        try partialData.setFixedWidthInteger(value, at: codingPath)
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
        let encoder = _PostgreSQLDataEncoder(partialData: partialData, at: codingPath)
        try value.encode(to: encoder)
    }

    /// See `SingleValueEncodingContainer.nestedContainer`
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey>
        where NestedKey: CodingKey
    {
        let container = PostgreSQLDataKeyedEncodingContainer<NestedKey>(partialData: partialData, at: codingPath)
        return .init(container)
    }

    /// See `SingleValueEncodingContainer.nestedSingleValueContainer`
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return PostgreSQLDataUnkeyedEncodingContainer(partialData: partialData, at: codingPath)
    }

    /// See `SingleValueEncodingContainer.superEncoder`
    func superEncoder() -> Encoder {
        return _PostgreSQLDataEncoder(partialData: partialData, at: codingPath)
    }
}
