public struct PostgresDataEncoder {
    public init() { }
    
    public func encode(_ type: Encodable) throws -> PostgresData {
        let encoder = _Encoder()
        try type.encode(to: encoder)
        return encoder.data
    }
    
    private final class _Encoder: Encoder {
        var codingPath: [CodingKey] {
            return []
        }
        
        var userInfo: [CodingUserInfoKey : Any] {
            return [:]
        }
        var data: PostgresData
        init() {
            self.data = .null
        }
        
        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            fatalError()
        }
        
        func unkeyedContainer() -> UnkeyedEncodingContainer {
            fatalError()
        }
        
        func singleValueContainer() -> SingleValueEncodingContainer {
            return _SingleValueEncoder(self)
        }
    }
    
    #warning("TODO: fix fatal errors")
    
    private struct _SingleValueEncoder: SingleValueEncodingContainer {
        var codingPath: [CodingKey] {
            return self.encoder.codingPath
        }
        
        let encoder: _Encoder
        init(_ encoder: _Encoder) {
            self.encoder = encoder
        }
        
        mutating func encodeNil() throws {
            // data already null
        }
        
        mutating func encode(_ value: Bool) throws {
            switch value {
            case true:
                self.encoder.data = PostgresData(int: 1)
            case false:
                self.encoder.data = PostgresData(int: 0)
            }
        }
        
        mutating func encode(_ value: String) throws {
            self.encoder.data = PostgresData(string: value)
        }
        
        mutating func encode(_ value: Double) throws {
            self.encoder.data = PostgresData(double: value)
        }
        
        mutating func encode(_ value: Float) throws {
            self.encoder.data = PostgresData(float: value)
        }
        
        mutating func encode(_ value: Int) throws {
            self.encoder.data = PostgresData(int: value)
        }
        
        mutating func encode(_ value: Int8) throws {
            fatalError()
        }
        
        mutating func encode(_ value: Int16) throws {
            fatalError()
        }
        
        mutating func encode(_ value: Int32) throws {
            fatalError()
        }
        
        mutating func encode(_ value: Int64) throws {
            self.encoder.data = PostgresData(int64: value)
        }
        
        mutating func encode(_ value: UInt) throws {
            fatalError()
        }
        
        mutating func encode(_ value: UInt8) throws {
            fatalError()
        }
        
        mutating func encode(_ value: UInt16) throws {
            fatalError()
        }
        
        mutating func encode(_ value: UInt32) throws {
            fatalError()
        }
        
        mutating func encode(_ value: UInt64) throws {
            fatalError()
        }
        
        mutating func encode<T>(_ value: T) throws where T : Encodable {
            fatalError()
        }
    }
}
