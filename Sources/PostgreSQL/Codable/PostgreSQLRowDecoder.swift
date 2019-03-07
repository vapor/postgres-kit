/// Decodes `Decodable` types from PostgreSQL row data.
struct PostgreSQLRowDecoder {
    /// Creates a new `PostgreSQLRowDecoder`.
    init() { }
    
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
        var allKeys: [Key] {
            // Unlikely to be called (mostly present for protocol conformance), so we don't need to cache this property.
            return row.keys
                .compactMap { col in
                    if tableOID == 0 || col.tableOID == tableOID || col.tableOID == 0 {
                        return col.name
                    } else {
                        return nil
                    }
                }.compactMap(Key.init(stringValue:))
        }
        
        init(row: [PostgreSQLColumn: PostgreSQLData], tableOID: UInt32) {
            self.row = row
            self.tableOID = tableOID
        }
        
        private func data(for key: Key) -> PostgreSQLData? {
            let columnName = key.stringValue
            var column = PostgreSQLColumn(tableOID: self.tableOID, name: columnName)
            // First, check for an exact (tableOID, columnName) match.
            var data = row[column]
            if data == nil {
                if self.tableOID != 0 {
                    // No column with our exact table OID; check for a (0, columnName) match instead.
                    column.tableOID = 0
                    data = row[column]
                } else {
                    // No (0, columnName) match; check via (slow!) linear search for _any_ matching column name,
                    // regardless of tableOID.
                    // Note: This path is hit in `PostgreSQLConnection.tableNames`, but luckily the `PGClass` only has
                    // two keys, so the performance impact of linear search is acceptable there.
                    return row.firstValue(tableOID: tableOID, name: columnName)
                }
            }
            return data
        }
        
        func contains(_ key: Key) -> Bool {
            return data(for: key) != nil
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            guard let data = data(for: key) else {
                return true
            }
            switch data.storage {
            case .null: return true
            default: return false
            }
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            guard let data = data(for: key) else {
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
