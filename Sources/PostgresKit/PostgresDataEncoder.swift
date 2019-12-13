import Foundation

public final class PostgresDataEncoder {
    public let json: JSONEncoder

    public init(json: JSONEncoder = JSONEncoder()) {
        self.json = json
    }

    public func encode(_ value: Encodable) throws -> PostgresData {
        if let custom = value as? PostgresDataConvertible {
            return custom.postgresData!
        } else {
            let context = _Context()
            try value.encode(to: _Encoder(context: context))
            if let value = context.value {
                return value
            } else if let array = context.array {
                return PostgresData(array: array, elementType: .jsonb)
            } else {
                return try PostgresData(jsonb: self.json.encode(_Wrapper(value)))
            }
        }
    }

    final class _Context {
        var value: PostgresData?
        var array: [PostgresData]?

        init() { }
    }

    struct _Encoder: Encoder {
        var userInfo: [CodingUserInfoKey : Any] {
            [:]
        }
        var codingPath: [CodingKey] {
            []
        }
        let context: _Context

        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key>
            where Key : CodingKey
        {
            .init(_KeyedEncoder<Key>())
        }

        func unkeyedContainer() -> UnkeyedEncodingContainer {
            self.context.array = []
            return _UnkeyedEncoder(context: self.context)
        }

        func singleValueContainer() -> SingleValueEncodingContainer {
            _ValueEncoder(context: self.context)
        }
    }

    struct _UnkeyedEncoder: UnkeyedEncodingContainer {
        var codingPath: [CodingKey] {
            []
        }
        var count: Int {
            0
        }

        var context: _Context

        func encodeNil() throws {
            self.context.array!.append(.null)
        }

        func encode<T>(_ value: T) throws where T : Encodable {
            try self.context.array!.append(PostgresDataEncoder().encode(value))
        }

        func nestedContainer<NestedKey>(
            keyedBy keyType: NestedKey.Type
        ) -> KeyedEncodingContainer<NestedKey>
            where NestedKey : CodingKey
        {
            fatalError()
        }

        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            fatalError()
        }

        func superEncoder() -> Encoder {
            fatalError()
        }
    }

    struct _KeyedEncoder<Key>: KeyedEncodingContainerProtocol
        where Key: CodingKey
    {
        var codingPath: [CodingKey] {
            []
        }

        func encodeNil(forKey key: Key) throws {
            // do nothing
        }

        func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            // do nothing
        }

        func nestedContainer<NestedKey>(
            keyedBy keyType: NestedKey.Type,
            forKey key: Key
        ) -> KeyedEncodingContainer<NestedKey>
            where NestedKey : CodingKey
        {
            fatalError()
        }

        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {

            fatalError()
        }

        func superEncoder() -> Encoder {
            fatalError()
        }

        func superEncoder(forKey key: Key) -> Encoder {
            fatalError()
        }
    }


    struct _ValueEncoder: SingleValueEncodingContainer {
        var codingPath: [CodingKey] {
            []
        }
        let context: _Context

        func encodeNil() throws {
            self.context.value = .null
        }

        func encode<T>(_ value: T) throws where T : Encodable {
            self.context.value = try PostgresDataEncoder().encode(value)
        }
    }

    struct _Wrapper: Encodable {
        let encodable: Encodable
        init(_ encodable: Encodable) {
            self.encodable = encodable
        }
        func encode(to encoder: Encoder) throws {
            try self.encodable.encode(to: encoder)
        }
    }
}
