/// Encodes `Encodable` objects to PostgreSQL row data.
public struct PostgreSQLRowEncoder {
    /// Creates a new `PostgreSQLRowEncoder`.
    public init() { }
    
    /// Encodes an `Encodable` object to `[PostgreSQLColumn: PostgreSQLData]`.
    ///
    /// - parameters:
    ///     - encodable: Item to encode.
    ///     - tableOID: Optional table OID to use when encoding.
    public func encode<E>(_ encodable: E, tableOID: UInt32? = nil) throws -> [PostgreSQLColumn: PostgreSQLData]
        where E: Encodable
    {
        let encoder = _PostgreSQLRowEncoder(tableOID: tableOID)
        try encodable.encode(to: encoder)
        return encoder.data
    }
}


// MARK: Private

private final class _PostgreSQLRowEncoder: Encoder {
    let codingPath: [CodingKey] = []
    let userInfo: [CodingUserInfoKey: Any] = [:]
    var data: [PostgreSQLColumn: PostgreSQLData]
    let tableOID: UInt32?
    init(tableOID: UInt32?) {
        self.data = [:]
        self.tableOID = tableOID
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = _PostgreSQLRowKeyedEncodingContainer<Key>(encoder: self)
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        unsupported()
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        unsupported()
    }
    
}

private struct _PostgreSQLRowKeyedEncodingContainer<K>: KeyedEncodingContainerProtocol
    where K: CodingKey
{
    var codingPath: [CodingKey]
    let encoder: _PostgreSQLRowEncoder
    init(encoder: _PostgreSQLRowEncoder) {
        self.encoder = encoder
        self.codingPath = []
    }
    
    func set(_ key: CodingKey, to value: PostgreSQLDataConvertible) throws {
        let col = PostgreSQLColumn(tableOID: encoder.tableOID ?? 0, name: key.stringValue)
        self.encoder.data[col] = try value.convertToPostgreSQLData()
    }
    
    mutating func encodeNil(forKey key: K) throws { try set(key, to: PostgreSQLData(null: .void)) }
    mutating func encode(_ value: Bool, forKey key: K) throws { try set(key, to: value) }
    mutating func encode(_ value: Int, forKey key: K) throws { try set(key, to: value) }
    mutating func encode(_ value: Int16, forKey key: K) throws { try set(key, to: value) }
    mutating func encode(_ value: Int32, forKey key: K) throws { try set(key, to: value) }
    mutating func encode(_ value: Int64, forKey key: K) throws { try set(key, to: value) }
    mutating func encode(_ value: UInt, forKey key: K) throws { try set(key, to: value) }
    mutating func encode(_ value: UInt8, forKey key: K) throws { try set(key, to: value) }
    mutating func encode(_ value: UInt16, forKey key: K) throws { try set(key, to: value) }
    mutating func encode(_ value: UInt32, forKey key: K) throws { try set(key, to: value) }
    mutating func encode(_ value: UInt64, forKey key: K) throws { try set(key, to: value) }
    mutating func encode(_ value: Double, forKey key: K) throws { try set(key, to: value) }
    mutating func encode(_ value: Float, forKey key: K) throws { try set(key, to: value) }
    mutating func encode(_ value: String, forKey key: K) throws { try set(key, to: value) }
    mutating func encodeIfPresent(_ value: Bool?, forKey key: K) throws { try _encodeIfPresent(value, forKey: key) }
    mutating func encodeIfPresent(_ value: Int?, forKey key: K) throws { try _encodeIfPresent(value, forKey: key) }
    mutating func encodeIfPresent(_ value: Int16?, forKey key: K) throws { try _encodeIfPresent(value, forKey: key) }
    mutating func encodeIfPresent(_ value: Int32?, forKey key: K) throws { try _encodeIfPresent(value, forKey: key) }
    mutating func encodeIfPresent(_ value: Int64?, forKey key: K) throws { try _encodeIfPresent(value, forKey: key) }
    mutating func encodeIfPresent(_ value: UInt?, forKey key: K) throws { try _encodeIfPresent(value, forKey: key) }
    mutating func encodeIfPresent(_ value: UInt8?, forKey key: K) throws { try _encodeIfPresent(value, forKey: key) }
    mutating func encodeIfPresent(_ value: UInt16?, forKey key: K) throws { try _encodeIfPresent(value, forKey: key) }
    mutating func encodeIfPresent(_ value: UInt32?, forKey key: K) throws { try _encodeIfPresent(value, forKey: key) }
    mutating func encodeIfPresent(_ value: UInt64?, forKey key: K) throws { try _encodeIfPresent(value, forKey: key) }
    mutating func encodeIfPresent(_ value: Double?, forKey key: K) throws { try _encodeIfPresent(value, forKey: key) }
    mutating func encodeIfPresent(_ value: Float?, forKey key: K) throws { try _encodeIfPresent(value, forKey: key) }
    mutating func encodeIfPresent(_ value: String?, forKey key: K) throws { try _encodeIfPresent(value, forKey: key) }
    mutating func encodeIfPresent<T>(_ value: T?, forKey key: K) throws where T: Encodable { try _encodeIfPresent(value, forKey: key) }
    
    mutating func superEncoder() -> Encoder { return encoder }
    mutating func superEncoder(forKey key: K) -> Encoder { return encoder }
    mutating func _encodeIfPresent<T>(_ value: T?, forKey key: K) throws where T : Encodable {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            if let convertibleType = T.self as? PostgreSQLDataConvertible.Type {
                try set(key, to: PostgreSQLData(null: convertibleType.postgreSQLDataType))
            } else {
                try encodeNil(forKey: key)
            }
        }
    }
    
    mutating func encode<T>(_ value: T, forKey key: K) throws where T: Encodable {
        guard let convertible = value as? PostgreSQLDataConvertible else {
            let type = Swift.type(of: value)
            throw PostgreSQLError(
                identifier: "convertible",
                reason: "Unsupported encodable type: \(type)",
                suggestedFixes: [
                    "Conform \(type) to PostgreSQLDataCustomConvertible"
                ]
            )
        }
        try set(key, to: convertible)
    }
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return encoder.container(keyedBy: NestedKey.self)
    }
    
    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        return encoder.unkeyedContainer()
    }
}

private func unsupported() -> Never {
    fatalError("""
    PostgreSQL rows only support a flat, keyed structure `[String: T]`.

    Query data must be an encodable dictionary, struct, or class.

    You can also conform nested types to `PostgreSQLJSONType` or `PostgreSQLArrayType`. (Nested types must be `PostgreSQLDataCustomConvertible`.)
    """)
}

