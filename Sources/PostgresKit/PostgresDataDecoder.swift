import Foundation
import protocol PostgresNIO.PostgresJSONDecoder
import var PostgresNIO._defaultJSONDecoder

public final class PostgresDataDecoder {
    public let json: PostgresNIO.PostgresJSONDecoder

    public init(json: PostgresNIO.PostgresJSONDecoder = PostgresNIO._defaultJSONDecoder) {
        self.json = json
    }

    public func decode<T>(_ type: T.Type, from data: PostgresData) throws -> T
        where T: Decodable
    {
        if let convertible = T.self as? PostgresDataConvertible.Type {
            guard let value = convertible.init(postgresData: data) else {
                throw DecodingError.typeMismatch(T.self, DecodingError.Context.init(
                    codingPath: [],
                    debugDescription: "Could not convert to \(T.self): \(data)"
                ))
            }
            return value as! T
        } else {
            return try T.init(from: _Decoder(data: data, json: self.json))
        }
    }

    enum Error: Swift.Error, CustomStringConvertible {
        case unexpectedDataType(PostgresDataType, expected: String)
        case nestingNotSupported

        var description: String {
            switch self {
            case .unexpectedDataType(let type, let expected):
                return "Unexpected data type: \(type). Expected \(expected)."
            case .nestingNotSupported:
                return "Decoding nested containers is not supported."
            }
        }
    }

    final class _Decoder: Decoder {
        var codingPath: [CodingKey] {
            return []
        }

        var userInfo: [CodingUserInfoKey : Any] {
            return [:]
        }

        let data: PostgresData
        let json: PostgresJSONDecoder

        init(data: PostgresData, json: PostgresJSONDecoder) {
            self.data = data
            self.json = json
        }

        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            guard let data = self.data.array else {
                throw Error.unexpectedDataType(self.data.type, expected: "array")
            }
            return _UnkeyedDecoder(data: data, json: self.json)
        }

        func container<Key>(
            keyedBy type: Key.Type
        ) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
            let data: Data
            if let jsonb = self.data.jsonb {
                data = jsonb
            } else if let json = self.data.json {
                data = json
            } else {
                throw Error.unexpectedDataType(self.data.type, expected: "json")
            }
            return try self.json
                .decode(DecoderUnwrapper.self, from: data)
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
        let json: PostgresJSONDecoder
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
            return try PostgresDataDecoder(json: self.json).decode(T.self, from: data)
        }

        mutating func nestedContainer<NestedKey>(
            keyedBy type: NestedKey.Type
        ) throws -> KeyedDecodingContainer<NestedKey>
            where NestedKey : CodingKey
        {
            throw Error.nestingNotSupported
        }

        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            throw Error.nestingNotSupported
        }

        mutating func superDecoder() throws -> Decoder {
            throw Error.nestingNotSupported
        }
    }

    struct _ValueDecoder: SingleValueDecodingContainer {
        let data: PostgresData
        let json: PostgresJSONDecoder
        var codingPath: [CodingKey] {
            []
        }

        func decodeNil() -> Bool {
            return self.data.value == nil
        }

        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            if let convertible = T.self as? PostgresDataConvertible.Type {
                guard let value = convertible.init(postgresData: data) else {
                    throw DecodingError.typeMismatch(T.self, DecodingError.Context.init(
                        codingPath: [],
                        debugDescription: "Could not convert to \(T.self): \(data)"
                    ))
                }
                return value as! T
            } else {
                return try T.init(from: _Decoder(data: self.data, json: self.json))
            }
        }
    }
}

struct DecoderUnwrapper: Decodable {
    let decoder: Decoder
    init(from decoder: Decoder) {
        self.decoder = decoder
    }
}
