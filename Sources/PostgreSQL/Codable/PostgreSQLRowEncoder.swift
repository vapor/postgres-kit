/// Encodes `Encodable` objects to PostgreSQL row data.
public struct PostgreSQLRowEncoder {
    /// Creates a new `PostgreSQLRowEncoder`.
    public init() { }
    
    /// Encodes an `Encodable` object to `[PostgreSQLColumn: PostgreSQLData]`.
    ///
    /// - parameters:
    ///     - encodable: Item to encode.
    ///     - tableOID: Optional table OID to use when encoding.
    public func encode<E>(_ encodable: E, tableOID: UInt32 = 0) throws -> [PostgreSQLColumn: PostgreSQLData]
        where E: Encodable
    {
        let encoder = _Encoder(tableOID: tableOID)
        try encodable.encode(to: encoder)
        return encoder.row
    }
    
    // MARK: Private
    
    private final class _Encoder: Encoder {
        let codingPath: [CodingKey] = []
        var userInfo: [CodingUserInfoKey: Any] = [:]
        var row: [PostgreSQLColumn: PostgreSQLData]
        let tableOID: UInt32
        
        init(tableOID: UInt32) {
            self.row = [:]
            self.tableOID = tableOID
        }
        
        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            return .init(_KeyedEncodingContainer(encoder: self))
        }
        
        func unkeyedContainer() -> UnkeyedEncodingContainer {
            fatalError()
        }
        
        func singleValueContainer() -> SingleValueEncodingContainer {
            fatalError()
        }
    }
    
    private struct _KeyedEncodingContainer<Key>: KeyedEncodingContainerProtocol where Key: CodingKey {
        let codingPath: [CodingKey] = []
        let encoder: _Encoder
        init(encoder: _Encoder) {
            self.encoder = encoder
        }
        
        mutating func encodeNil(forKey key: Key) throws {
            encoder.row[.init(tableOID: encoder.tableOID, name: key.stringValue)] = .null
        }
        
        mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            encoder.row[.init(tableOID: encoder.tableOID, name: key.stringValue)] = try PostgreSQLDataEncoder().encode(value)
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError()
        }
        
        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            fatalError()
        }
        
        mutating func superEncoder() -> Encoder {
            fatalError()
        }
        
        mutating func superEncoder(forKey key: Key) -> Encoder {
            fatalError()
        }
    }
}


public struct SQLRowEncoder<Database> where Database: SQLSupporting {
    public init() { }
    
    public func encode<E>(_ encodable: E, tableName: String? = nil) throws -> [Query<Database>.DML.Column: Query<Database>.DML.Value]
        where E: Encodable
    {
        let encoder = _Encoder(tableName: tableName)
        try encodable.encode(to: encoder)
        return encoder.row
    }
    
    // MARK: Private
    
    private final class _Encoder: Encoder {
        let codingPath: [CodingKey] = []
        var userInfo: [CodingUserInfoKey: Any] = [:]
        var row: [Query<Database>.DML.Column: Query<Database>.DML.Value]
        let tableName: String?
        
        init(tableName: String?) {
            self.row = [:]
            self.tableName = tableName
        }
        
        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            return .init(_KeyedEncodingContainer(encoder: self))
        }
        
        func unkeyedContainer() -> UnkeyedEncodingContainer {
            fatalError()
        }
        
        func singleValueContainer() -> SingleValueEncodingContainer {
            fatalError()
        }
    }
    
    private struct _KeyedEncodingContainer<Key>: KeyedEncodingContainerProtocol where Key: CodingKey {
        let codingPath: [CodingKey] = []
        let encoder: _Encoder
        init(encoder: _Encoder) {
            self.encoder = encoder
        }
        
        mutating func encodeNil(forKey key: Key) throws {
            encoder.row[.init(table: encoder.tableName, name: key.stringValue)] = .null
        }
        
        mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            encoder.row[.init(table: encoder.tableName, name: key.stringValue)] = .bind(value)
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError()
        }
        
        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            fatalError()
        }
        
        mutating func superEncoder() -> Encoder {
            fatalError()
        }
        
        mutating func superEncoder(forKey key: Key) -> Encoder {
            fatalError()
        }
    }
}



