import Foundation

struct DecoderUnwrapper: Decodable {
    let decoder: Decoder
    init(from decoder: Decoder) {
        self.decoder = decoder
    }
}

public final class PostgresDataDecoder {
    public let jsonDecoder: JSONDecoder

    public init(json: JSONDecoder = JSONDecoder()) {
        self.jsonDecoder = json
    }

    public func decode<T>(_ type: T.Type, from data: PostgresData) throws -> T
        where T: Decodable
    {
        if let convertible = T.self as? PostgresDataConvertible.Type {
            return convertible.init(postgresData: data)! as! T
        } else {
            return try T.init(from: _Decoder(data: data, json: self.jsonDecoder))
        }
    }

    enum _Error: Error {
        case keyedElement
        case unkeyedArray
        case arrayElementJSON
        case nesting
    }

    final class _Decoder: Decoder {
        var codingPath: [CodingKey] {
            return []
        }

        var userInfo: [CodingUserInfoKey : Any] {
            return [:]
        }

        let data: PostgresData
        let json: JSONDecoder

        init(data: PostgresData, json: JSONDecoder) {
            self.data = data
            self.json = json
        }

        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            print(self.data.type)
            guard let data = self.data.array else {
                throw _Error.unkeyedArray
            }
            return _UnkeyedDecoder(data: data, json: self.json)
        }

        func container<Key>(
            keyedBy type: Key.Type
        ) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
            guard self.data.type == .jsonb else {
                throw _Error.arrayElementJSON
            }
            guard let json = self.data.jsonb else {
                throw _Error.arrayElementJSON
            }
            return try self.json
                .decode(DecoderUnwrapper.self, from: json)
                .decoder.container(keyedBy: Key.self)
        }

        func singleValueContainer() throws -> SingleValueDecodingContainer {
            _ValueDecoder(data: self.data, json: self.json)
        }
    }

    struct _UnkeyedDecoder: UnkeyedDecodingContainer {
        var count: Int? {
            self.data.count
        }

        var isAtEnd: Bool {
            self.currentIndex == self.data.count
        }
        var currentIndex: Int = 0

        let data: [PostgresData]
        let json: JSONDecoder
        var codingPath: [CodingKey] {
            []
        }

        mutating func decodeNil() throws -> Bool {
            defer { self.currentIndex += 1 }
            return self.data[self.currentIndex].value == nil
        }

        mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            defer { self.currentIndex += 1 }
            let data = self.data[self.currentIndex]
            guard data.type == .jsonb else {
                throw _Error.arrayElementJSON
            }
            guard let json = data.jsonb else {
                throw _Error.arrayElementJSON
            }
            return try self.json.decode(T.self, from: json)
        }

        mutating func nestedContainer<NestedKey>(
            keyedBy type: NestedKey.Type
        ) throws -> KeyedDecodingContainer<NestedKey>
            where NestedKey : CodingKey
        {
            throw _Error.nesting
        }

        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            throw _Error.nesting
        }

        mutating func superDecoder() throws -> Decoder {
            throw _Error.nesting
        }
    }

    struct _ValueDecoder: SingleValueDecodingContainer {
        let data: PostgresData
        let json: JSONDecoder
        var codingPath: [CodingKey] {
            []
        }

        func decodeNil() -> Bool {
            return self.data.value == nil
        }

        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            if let convertible = T.self as? PostgresDataConvertible.Type {
                return convertible.init(postgresData: self.data)! as! T
            } else {
                return try T.init(from: _Decoder(data: self.data, json: self.json))
            }
        }
    }
}
