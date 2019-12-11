import Foundation

public struct PostgresDataEncoder {
    public init() { }

    public func encode(_ value: Encodable) throws -> PostgresData {
        if let custom = value as? PostgresDataConvertible {
            return custom.postgresData!
        } else {
            do {
                let encoder = _Encoder()
                try value.encode(to: encoder)
                return encoder.data
            } catch is DoJSON {
                return try PostgresData(jsonb: Wrapper(value))
            }
        }
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
            .init(_KeyedValueEncoder(self))
        }

        func unkeyedContainer() -> UnkeyedEncodingContainer {
            _UnkeyedEncodingContainer(self)
        }

        func singleValueContainer() -> SingleValueEncodingContainer {
            _SingleValueEncoder(self)
        }
    }

    struct DoJSON: Error {}

    struct Wrapper: Encodable {
        let encodable: Encodable
        init(_ encodable: Encodable) {
            self.encodable = encodable
        }
        func encode(to encoder: Encoder) throws {
            try self.encodable.encode(to: encoder)
        }
    }

    private struct _UnkeyedEncodingContainer: UnkeyedEncodingContainer {
        var codingPath: [CodingKey] {
            self.encoder.codingPath
        }
        var count: Int {
            0
        }

        let encoder: _Encoder
        init(_ encoder: _Encoder) {
            self.encoder = encoder
        }

        mutating func encodeNil() throws {
            throw DoJSON()
        }

        mutating func encode<T>(_ value: T) throws where T : Encodable {
            throw DoJSON()
        }

        mutating func nestedContainer<NestedKey>(
            keyedBy keyType: NestedKey.Type
        ) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            self.encoder.container(keyedBy: NestedKey.self)
        }

        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            self.encoder.unkeyedContainer()
        }

        mutating func superEncoder() -> Encoder {
            self.encoder
        }
    }

    private struct _KeyedValueEncoder<Key>: KeyedEncodingContainerProtocol where Key: CodingKey {
        var codingPath: [CodingKey] {
            self.encoder.codingPath
        }

        let encoder: _Encoder
        init(_ encoder: _Encoder) {
            self.encoder = encoder
        }

        mutating func encodeNil(forKey key: Key) throws {
            throw DoJSON()
        }

        mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            throw DoJSON()
        }

        mutating func nestedContainer<NestedKey>(
            keyedBy keyType: NestedKey.Type,
            forKey key: Key
        ) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            self.encoder.container(keyedBy: NestedKey.self)
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            self.encoder.unkeyedContainer()
        }

        mutating func superEncoder() -> Encoder {
            self.encoder
        }

        mutating func superEncoder(forKey key: Key) -> Encoder {
            self.encoder
        }
    }


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

        mutating func encode<T>(_ value: T) throws where T : Encodable {
            if let value = value as? PostgresDataConvertible {
                guard let data = value.postgresData else {
                    let context = DecodingError.Context(
                        codingPath: self.codingPath,
                        debugDescription: "Could not convert \(value) to PostgresData"
                    )
                    throw DecodingError.typeMismatch(T.self, context)
                }
                self.encoder.data = data
            } else {
                try value.encode(to: self.encoder)
            }
        }
    }
}
