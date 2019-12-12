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
            let encoder = _Encoder(codingPath: [])
            try Wrapper(value).encode(to: encoder)
            guard let data = encoder.data?.resolve() else {
                // no containers made
                return .null
            }
            switch data {
            case .array(let array):
                return try PostgresData(
                    array: array.map { item -> PostgresData in
                        let data = try self.json.encode(item)
                        return PostgresData(jsonb: data)
                    },
                    elementType: .jsonb
                )
            case .dictionary(let dictionary):
                let data = try self.json.encode(dictionary)
                return PostgresData(jsonb: data)
            case .null:
                return .null
            case .encodable(let encodable):
                return try self.encode(encodable)
            }
        }
    }
}

private final class _Encoder: Encoder {
    var userInfo: [CodingUserInfoKey : Any] {
        return [:]
    }
    var codingPath: [CodingKey]
    var data: _Data?
    init(codingPath: [CodingKey]) {
        self.codingPath = codingPath
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key>
        where Key : CodingKey
    {
        let container = _KeyedEncoder<Key>(codingPath: self.codingPath)
        self.data = .container(container)
        return .init(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let container = _UnkeyedEncoder(codingPath: self.codingPath)
        self.data = .container(container)
        return container
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        let container = _ValueEncoder(codingPath: self.codingPath)
        self.data = .container(container)
        return container
    }
}

private final class _UnkeyedEncoder: UnkeyedEncodingContainer, _Container {
    var codingPath: [CodingKey]
    var count: Int {
        self.items.count
    }
    var data: _Data {
        .array(self.items)
    }
    var items: [_Data]

    init(codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.items = []
    }

    func encodeNil() throws {
        self.items.append(.null)
    }

    func encode<T>(_ value: T) throws where T : Encodable {
        self.items.append(.encodable(value))
    }

    func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey>
        where NestedKey : CodingKey
    {
        let container = _KeyedEncoder<NestedKey>(codingPath: self.codingPath)
        self.items.append(.container(container))
        return .init(container)
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let container = _UnkeyedEncoder(codingPath: self.codingPath)
        self.items.append(.container(container))
        return container
    }

    func superEncoder() -> Encoder {
        _Encoder(codingPath: self.codingPath)
    }
}

private final class _KeyedEncoder<Key>: KeyedEncodingContainerProtocol, _Container
    where Key: CodingKey
{
    var codingPath: [CodingKey]
    var data: _Data {
        .dictionary(self.items)
    }
    var items: [String: _Data]

    init(codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.items = [:]
    }

    func encodeNil(forKey key: Key) throws {
        self.items[key.stringValue] = .null
    }

    func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        self.items[key.stringValue] = .encodable(value)
    }

    func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey>
        where NestedKey : CodingKey
    {
        let container = _KeyedEncoder<NestedKey>(codingPath: self.codingPath)
        self.items[key.stringValue] = .container(container)
        return .init(container)
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let container = _UnkeyedEncoder(codingPath: self.codingPath)
        self.items[key.stringValue] = .container(container)
        return container
    }

    func superEncoder() -> Encoder {
        _Encoder(codingPath: self.codingPath)
    }

    func superEncoder(forKey key: Key) -> Encoder {
        _Encoder(codingPath: self.codingPath + [key])
    }
}


private final class _ValueEncoder: SingleValueEncodingContainer, _Container {
    var codingPath: [CodingKey]
    var data: _Data

    init(codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.data = .null
    }

    func encodeNil() throws {
        self.data = .null
    }

    func encode<T>(_ value: T) throws where T : Encodable {
        self.data = .encodable(value)
    }
}

struct Wrapper: Encodable {
    let encodable: Encodable
    init(_ encodable: Encodable) {
        self.encodable = encodable
    }
    func encode(to encoder: Encoder) throws {
        try self.encodable.encode(to: encoder)
    }
}

protocol _Container {
    var data: _Data { get }
}

enum _Value: Encodable {
    case array([_Value])
    case dictionary([String: _Value])
    case null
    case encodable(Encodable)

    func encode(to encoder: Encoder) throws {
        switch self {
        case .array(let array):
            var container = encoder.unkeyedContainer()
            try array.forEach { try container.encode($0) }
        case .dictionary(let dictionary):
            var container = encoder.container(keyedBy: _Key.self)
            try dictionary.forEach {
                try container.encode($0.value, forKey: .init($0.key))
            }
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        case .encodable(let encodable):
            try encodable.encode(to: encoder)
        }
    }
}

struct _Key: CodingKey {
    var stringValue: String
    var intValue: Int? {
        Int(self.stringValue)
    }

    init(_ string: String) {
        self.stringValue = string
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.stringValue = intValue.description
    }
}

enum _Data {
    case array([_Data])
    case dictionary([String: _Data])
    case null
    case container(_Container)
    case encodable(Encodable)

    func resolve() -> _Value {
        switch self {
        case .array(let array):
            return .array(array.map { $0.resolve() })
        case .dictionary(let dictionary):
            return .dictionary(dictionary.mapValues { $0.resolve() })
        case .null:
            return .null
        case .container(let container):
            return container.data.resolve()
        case .encodable(let encodable):
            return .encodable(encodable)
        }
    }
}
