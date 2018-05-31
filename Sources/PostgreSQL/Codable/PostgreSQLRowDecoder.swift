/// Decodes `Decodable` types from PostgreSQL row data.
public struct PostgreSQLRowDecoder {
    /// Creates a new `PostgreSQLRowDecoder`.
    public init() { }
    
    /// Decodes a `Decodable` object from `[DataColumn: PostgreSQLData]`.
    ///
    /// - parameters:
    ///     - decodable: Type to decode.
    ///     - row: PostgreSQL row to decode.
    ///     - tableName: Optional table OID to use when decoding. If supplied, columns with table OIDs
    ///                  can be matched while decoding. Columns without table OIDs will always match if the column name matches.
    /// - returns: Instance of Decodable type.
    public func decode<D>(_ decodable: D.Type, from row: [PostgreSQLColumn: PostgreSQLData], tableOID: UInt32? = nil) throws -> D
        where D: Decodable
    {
        let decoder = _PostgreSQLRowDecoder(row: row, tableOID: tableOID)
        return try D.init(from: decoder)
    }
}

// MARK: Private

private final class _PostgreSQLRowDecoder: Decoder {
    let codingPath: [CodingKey] = []
    let userInfo: [CodingUserInfoKey: Any] = [:]
    let data: [PostgreSQLColumn: PostgreSQLData]
    let tableOID: UInt32?
    init(row: [PostgreSQLColumn: PostgreSQLData], tableOID: UInt32?) {
        self.data = row
        self.tableOID = tableOID
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        let container = PostgreSQLRowKeyedDecodingContainer<Key>(decoder: self)
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw unsupported()
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw unsupported()
    }
    
    func get(key: CodingKey) -> PostgreSQLData? {
        guard let value = data[.init(tableOID: tableOID ?? 0, name: key.stringValue)] else {
            guard let value = data[.init(tableOID: 0, name: key.stringValue)], tableOID != 0 else {
                return nil
            }
            return value
        }
        return value
    }
    
    func require(key: CodingKey) throws -> PostgreSQLData {
        guard let data = get(key: key) else {
            throw PostgreSQLError(identifier: "decode", reason: "No value found at key: \(key)")
        }
        return data
    }
    
}

private struct PostgreSQLRowKeyedDecodingContainer<K>: KeyedDecodingContainerProtocol
    where K: CodingKey
{
    var allKeys: [K]
    typealias Key = K
    let codingPath: [CodingKey] = []
    let decoder: _PostgreSQLRowDecoder
    init(decoder: _PostgreSQLRowDecoder) {
        self.decoder = decoder
        allKeys = self.decoder.data.keys.compactMap {
            if $0.tableOID == decoder.tableOID || $0.tableOID == 0 {
                return K(stringValue: $0.name)
            } else {
                return nil
            }
        }
    }
    
    func contains(_ key: K) -> Bool { return allKeys.contains { $0.stringValue == key.stringValue } }
    func decodeNil(forKey key: K) -> Bool {
        if let value = decoder.get(key: key) {
            return value.isNull
        } else {
            return true
        }
    }
    func decode(_ type: Int.Type, forKey key: K) throws -> Int { return try decoder.require(key: key).decode(Int.self) }
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 { return try decoder.require(key: key).decode(Int8.self) }
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 { return try decoder.require(key: key).decode(Int16.self) }
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 { return try decoder.require(key: key).decode(Int32.self) }
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 { return try decoder.require(key: key).decode(Int64.self) }
    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt { return try decoder.require(key: key).decode(UInt.self) }
    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 { return try decoder.require(key: key).decode(UInt8.self) }
    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 { return try decoder.require(key: key).decode(UInt16.self) }
    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 { return try decoder.require(key: key).decode(UInt32.self) }
    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 { return try decoder.require(key: key).decode(UInt64.self) }
    func decode(_ type: Double.Type, forKey key: K) throws -> Double { return try decoder.require(key: key).decode(Double.self) }
    func decode(_ type: Float.Type, forKey key: K) throws -> Float { return try decoder.require(key: key).decode(Float.self) }
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool { return try decoder.require(key: key).decode(Bool.self) }
    func decode(_ type: String.Type, forKey key: K) throws -> String { return try decoder.require(key: key).decode(String.self) }
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        guard let convertible = type as? PostgreSQLDataConvertible.Type else {
            throw PostgreSQLError(
                identifier: "convertible",
                reason: "Unsupported decodable type: \(type)",
                suggestedFixes: [
                    "Conform \(type) to PostgreSQLDataCustomConvertible"
                ]
            )
        }
        return try convertible.convertFromPostgreSQLData(decoder.require(key: key)) as! T
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        return try decoder.container(keyedBy: NestedKey.self)
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        return try decoder.unkeyedContainer()
    }
    
    func superDecoder() throws -> Decoder { return decoder }
    func superDecoder(forKey key: K) throws -> Decoder { return decoder }
}

private func unsupported() -> PostgreSQLError {
    return PostgreSQLError(
        identifier: "rowDecode",
        reason: "PostgreSQL rows only support a flat, keyed structure `[String: T]`",
        suggestedFixes: [
            "You can conform nested types to `PostgreSQLJSONType` or `PostgreSQLArrayType`. (Nested types must be `PostgreSQLDataCustomConvertible`.)"
        ]
    )
}
