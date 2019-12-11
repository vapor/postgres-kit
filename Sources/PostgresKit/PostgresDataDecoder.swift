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

    private final class _Decoder: Decoder {
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
            try self.jsonDecoder().unkeyedContainer()
        }

        func container<Key>(
            keyedBy type: Key.Type
        ) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
            try self.jsonDecoder().container(keyedBy: Key.self)
        }

        func jsonDecoder() throws -> Decoder {
            guard let buffer = self.data.value else {
                throw DecodingError.valueNotFound(Any.self, .init(
                    codingPath: self.codingPath,
                    debugDescription: "Cannot decode JSON from nil value"
                ))
            }
            let unwrapper = try self.json
                .decode(DecoderUnwrapper.self, from: Data(buffer.readableBytesView))
            return unwrapper.decoder
        }

        func singleValueContainer() throws -> SingleValueDecodingContainer {
            return _SingleValueDecoder(self)
        }
    }

    private struct _SingleValueDecoder: SingleValueDecodingContainer {
        var codingPath: [CodingKey] {
            return self.decoder.codingPath
        }
        let decoder: _Decoder
        init(_ decoder: _Decoder) {
            self.decoder = decoder
        }

        func decodeNil() -> Bool {
            return self.decoder.data.value == nil
        }

        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            if let convertible = T.self as? PostgresDataConvertible.Type {
                return convertible.init(postgresData: self.decoder.data)! as! T
            } else {
                return try T.init(from: self.decoder)
            }
        }
    }
}
