/// Internal `UnkeyedEncodingContainer` for `PostgreSQLDataEncoder`.
internal final class PostgreSQLDataUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    /// See `UnkeyedEncodingContainer.count`
    var count: Int

    /// See `KeyedEncodingContainerProtocol.codingPath`
    var codingPath: [CodingKey]

    /// Data being encoded.
    let partialData: PartialPostgreSQLData

    /// Creates a coding key for the current index, then increments the count.
    var index: CodingKey {
        defer { count += 1 }
        return PostgreSQLDataArrayKey(count)
    }

    /// Creates a new `PostgreSQLDataKeyedEncodingContainer`
    init(partialData: PartialPostgreSQLData, at path: [CodingKey]) {
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
        try partialData.setFixedWidthInteger(value, at: codingPath + [index])
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
        try partialData.setFixedWidthInteger(value, at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: UInt8) throws {
        try partialData.setFixedWidthInteger(value, at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: UInt16) throws {
        try partialData.setFixedWidthInteger(value, at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: UInt32) throws {
        try partialData.setFixedWidthInteger(value, at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.encode`
    func encode(_ value: UInt64) throws {
        try partialData.setFixedWidthInteger(value, at: codingPath + [index])
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
        let encoder = _PostgreSQLDataEncoder(partialData: partialData, at: codingPath + [index])
        try value.encode(to: encoder)
    }

    /// See `UnkeyedEncodingContainer.nestedContainer`
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey>
        where NestedKey: CodingKey
    {
        let container = PostgreSQLDataKeyedEncodingContainer<NestedKey>(partialData: partialData, at: codingPath + [index])
        return .init(container)
    }

    /// See `UnkeyedEncodingContainer.nestedUnkeyedContainer`
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return PostgreSQLDataUnkeyedEncodingContainer(partialData: partialData, at: codingPath + [index])
    }

    /// See `UnkeyedEncodingContainer.superEncoder`
    func superEncoder() -> Encoder {
        return _PostgreSQLDataEncoder(partialData: partialData, at: codingPath + [index])
    }
}

/// Represents an array index.
struct PostgreSQLDataArrayKey: CodingKey {
    /// See `CodingKey.intValue`
    var intValue: Int?

    /// See `CodingKey.stringValue`
    var stringValue: String

    /// See `CodingKey.init(stringValue:)`
    init?(stringValue: String) {
        return nil
    }

    /// See `CodingKey.init(intValue:)`
    init?(intValue: Int) {
        self.init(intValue)
    }

    /// Creates a new `PostgreSQLDataArrayKey` from the supplied index.
    init(_ index: Int) {
        self.intValue = index
        self.stringValue = index.description
    }
}
