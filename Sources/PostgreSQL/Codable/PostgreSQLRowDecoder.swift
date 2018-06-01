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
    public func decode<D>(_ decodable: D.Type, from row: [PostgreSQLColumn: PostgreSQLData], tableOID: UInt32 = 0) throws -> D
        where D: Decodable
    {
        return try D(from: _Decoder(row: row, tableOID: tableOID))
    }
    
    // MARK: Private
    
    private struct _Decoder: Decoder {
        let codingPath: [CodingKey] = []
        var userInfo: [CodingUserInfoKey: Any] = [:]
        let row: [PostgreSQLColumn: PostgreSQLData]
        let tableOID: UInt32
        
        init(row: [PostgreSQLColumn: PostgreSQLData], tableOID: UInt32) {
            self.row = row
            self.tableOID = tableOID
        }
    
        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
            return .init(_KeyedDecodingContainer(row: row, tableOID: tableOID))
        }
        
        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            fatalError()
        }
        
        func singleValueContainer() throws -> SingleValueDecodingContainer {
            fatalError()
        }
    }
    
    private struct _KeyedDecodingContainer<Key>: KeyedDecodingContainerProtocol where Key: CodingKey {
        let codingPath: [CodingKey] = []
        let row: [PostgreSQLColumn: PostgreSQLData]
        let tableOID: UInt32
        let allKeys: [Key]
        
        init(row: [PostgreSQLColumn: PostgreSQLData], tableOID: UInt32) {
            self.row = row
            self.tableOID = tableOID
            self.allKeys = row.keys.compactMap { col in
                if col.tableOID == 0 || col.tableOID == tableOID {
                    return col.name
                } else {
                    return nil
                }
            }.compactMap(Key.init(stringValue:))
        }
        
        func contains(_ key: Key) -> Bool {
            return allKeys.contains { $0.stringValue == key.stringValue }
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            guard let data = row[.init(tableOID: tableOID, name: key.stringValue)] else {
                return true
            }
            switch data.storage {
            case .null: return true
            default: return false
            }
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            guard let data = row[.init(tableOID: tableOID, name: key.stringValue)] else {
                throw DecodingError.valueNotFound(T.self, .init(codingPath: codingPath + [key], debugDescription: "Could not decode \(T.self)."))
            }
            return try PostgreSQLDataDecoder().decode(T.self, from: data)
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError()
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            fatalError()
        }
        
        func superDecoder() throws -> Decoder {
            fatalError()
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            fatalError()
        }
    }
}
