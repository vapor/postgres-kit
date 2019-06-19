import Foundation

struct DecoderUnwrapper: Decodable {
    let decoder: Decoder
    init(from decoder: Decoder) {
        self.decoder = decoder
    }
}

public struct PostgresDataDecoder {
    public init() {}

    public func decode<T>(_ type: T.Type, from data: PostgresData) throws -> T
        where T: Decodable
    {
        if let convertible = T.self as? PostgresDataConvertible.Type {
            return convertible.init(postgresData: data)! as! T
        } else {
            return try T.init(from: _Decoder(data: data))
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
        init(data: PostgresData) {
            self.data = data
        }

        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            fatalError()
        }

        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
            var buffer = self.data.value!
            let data = buffer.readBytes(length: buffer.readableBytes)!
            let unwrapper = try JSONDecoder().decode(DecoderUnwrapper.self, from: Data(data))
            return try unwrapper.decoder.container(keyedBy: Key.self)
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
