import Foundation
import PostgresNIO

@available(*, deprecated, message: "Use `PostgresDecodingContext` instead.")
public final class PostgresDataDecoder {
    public let json: any PostgresJSONDecoder

    public init(json: any PostgresJSONDecoder = PostgresNIO._defaultJSONDecoder) {
        self.json = json
    }

    public func decode<T>(_: T.Type, from data: PostgresData) throws -> T
        where T: Decodable
    {
        // If `T` can be converted directly, just do so.
        if let convertible = T.self as? any PostgresDataConvertible.Type {
            guard let value = convertible.init(postgresData: data) else {
                throw DecodingError.typeMismatch(T.self, .init(
                    codingPath: [],
                    debugDescription: "Could not convert PostgreSQL data to \(T.self): \(data as Any)"
                ))
            }
            return value as! T
        } else {
            // Probably a Postgres array, JSON array/object, or enum type not using @Enum. See if it can be "unwrapped"
            // as a single-value decoding container, since this is much faster than attempting a JSON decode, or as an
            // array in the Postgres-native sense; this will handle "box" types such as `RawRepresentable` enums while
            // still allowing falling back to JSON.
            do {
                return try T.init(from: GiftBoxUnwrapDecoder(decoder: self, data: data))
            } catch DecodingError.dataCorrupted {
                // Couldn't unwrap it either. Fall back to attempting a JSON decode.
                guard let jsonData = data.jsonb ?? data.json else {
                    throw Error.unexpectedDataType(data.type, expected: "jsonb/json")
                }
                return try self.json.decode(T.self, from: jsonData)
            }
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

    private final class GiftBoxUnwrapDecoder: Decoder, SingleValueDecodingContainer {
        var codingPath: [any CodingKey] { [] }
        var userInfo: [CodingUserInfoKey : Any] { [:] }

        let dataDecoder: PostgresDataDecoder
        let data: PostgresData

        init(decoder: PostgresDataDecoder, data: PostgresData) {
            self.dataDecoder = decoder
            self.data = data
        }
        
        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Dictionary containers must be JSON-encoded")
        }

        func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
            guard let array = self.data.array else {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Non-natively typed arrays must be JSON-encoded")
            }
            return ArrayContainer(data: array, dataDecoder: self.dataDecoder)
        }
        
        struct ArrayContainer: UnkeyedDecodingContainer {
            let data: [PostgresData]
            let dataDecoder: PostgresDataDecoder
            var codingPath: [any CodingKey] { [] }
            var count: Int? { self.data.count }
            var isAtEnd: Bool { self.currentIndex >= self.data.count }
            var currentIndex: Int = 0
            
            mutating func decodeNil() throws -> Bool {
                // Do _not_ shorten this using `defer`, otherwise `currentIndex` is incorrectly incremented.
                if self.data[self.currentIndex].value == nil {
                    self.currentIndex += 1
                    return true
                }
                return false
            }
            
            mutating func decode<T>(_: T.Type) throws -> T where T: Decodable {
                // Do _not_ shorten this using `defer`, otherwise `currentIndex` is incorrectly incremented.
                let result = try self.dataDecoder.decode(T.self, from: self.data[self.currentIndex])
                self.currentIndex += 1
                return result
            }
            
            mutating func nestedContainer<NewKey: CodingKey>(keyedBy _: NewKey.Type) throws -> KeyedDecodingContainer<NewKey> {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Data nesting is not supported")
            }
            
            mutating func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Data nesting is not supported")
            }
            
            mutating func superDecoder() throws -> any Decoder {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Data nesting is not supported")
            }
        }
        
        func singleValueContainer() throws -> any SingleValueDecodingContainer {
            return self
        }
        
        func decodeNil() -> Bool {
            self.data.value == nil
        }

        func decode<T>(_: T.Type) throws -> T where T: Decodable {
            // Recurse back into the data decoder, don't repeat its logic here.
            return try self.dataDecoder.decode(T.self, from: self.data)
        }
    }

    @available(*, deprecated, renamed: "json")
    public var jsonDecoder: JSONDecoder {
        return self.json as! JSONDecoder
    }
}
