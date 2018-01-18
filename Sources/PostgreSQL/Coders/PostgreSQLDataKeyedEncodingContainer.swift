/// Internal `KeyedEncodingContainerProtocol` for `PostgreSQLDataEncoder`.
internal final class PostgreSQLDataKeyedEncodingContainer<K>: KeyedEncodingContainerProtocol
    where K: CodingKey
{
    /// See `KeyedEncodingContainerProtocol.Key`
    var codingPath: [CodingKey]

    /// Data being encoded.
    let partialData: PartialPostgreSQLData

    /// Creates a new `PostgreSQLDataKeyedEncodingContainer`
    init(partialData: PartialPostgreSQLData, at path: [CodingKey]) {
        self.codingPath = path
        self.partialData = partialData
    }

    /// See `KeyedEncodingContainerProtocol.encodeNil`
    func encodeNil(forKey key: K) throws {
        try partialData.set(.null, at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: Bool, forKey key: K) throws {
        try partialData.set(.bool(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: Int, forKey key: K) throws {
        switch MemoryLayout<Int>.size {
        case 8: try partialData.set(.int64(Int64(value)), at: codingPath + [key])
        case 4: try partialData.set(.int32(Int32(value)), at: codingPath + [key])
        default: fatalError("Unsuported MemoryLayout<Int>.size")
        }
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: Int8, forKey key: K) throws {
        try partialData.set(.int8(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: Int16, forKey key: K) throws {
        try partialData.set(.int16(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: Int32, forKey key: K) throws {
        try partialData.set(.int32(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: Int64, forKey key: K) throws {
        try partialData.set(.int64(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: UInt, forKey key: K) throws {
        guard value <= UInt(Int64.max) else {
            throw PostgreSQLError(identifier: "uint", reason: "UInt value \(value) too large to store in Int64.")
        }
        try encode(Int64(value), forKey: key)
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: UInt8, forKey key: K) throws {
        guard value <= UInt(Int8.max) else {
            throw PostgreSQLError(identifier: "uint", reason: "UInt8 value \(value) too large to store in Int8.")
        }
        try encode(Int8(value), forKey: key)
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: UInt16, forKey key: K) throws {
        guard value <= UInt(Int16.max) else {
            throw PostgreSQLError(identifier: "uint", reason: "UInt16 value \(value) too large to store in Int16.")
        }
        try encode(Int16(value), forKey: key)
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: UInt32, forKey key: K) throws {
        guard value <= UInt(Int32.max) else {
            throw PostgreSQLError(identifier: "uint", reason: "UInt32 value \(value) too large to store in Int32.")
        }
        try encode(Int32(value), forKey: key)
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: UInt64, forKey key: K) throws {
        guard value <= UInt(Int64.max) else {
            throw PostgreSQLError(identifier: "uint", reason: "UInt64 value \(value) too large to store in Int64.")
        }
        try encode(Int64(value), forKey: key)
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: Float, forKey key: K) throws {
        try partialData.set(.float(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: Double, forKey key: K) throws {
        try partialData.set(.double(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode(_ value: String, forKey key: K) throws {
        try partialData.set(.string(value), at: codingPath + [key])
    }

    /// See `KeyedEncodingContainerProtocol.encode`
    func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        let encoder = _PostgreSQLDataEncoder(partialData: partialData, at: codingPath + [key])
        try value.encode(to: encoder)
    }

    /// See `KeyedEncodingContainerProtocol.nestedContainer`
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey>
        where NestedKey: CodingKey
    {
        let container = PostgreSQLDataKeyedEncodingContainer<NestedKey>(partialData: partialData, at: codingPath + [key])
        return .init(container)
    }

    /// See `KeyedEncodingContainerProtocol.nestedUnkeyedContainer`
    func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        fatalError("Not yet supported")
    }

    /// See `KeyedEncodingContainerProtocol.superEncoder`
    func superEncoder() -> Encoder {
        return _PostgreSQLDataEncoder(partialData: partialData, at: codingPath)
    }

    /// See `KeyedEncodingContainerProtocol.superEncoder`
    func superEncoder(forKey key: K) -> Encoder {
        return _PostgreSQLDataEncoder(partialData: partialData, at: codingPath + [key])
    }
}
