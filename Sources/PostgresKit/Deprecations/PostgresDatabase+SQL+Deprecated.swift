import PostgresNIO
import Foundation
import SQLKit

@available(*, deprecated, message: "Use `.sql(jsonEncoder:jsonDecoder:)` instead.")
extension PostgresDatabase {
    @inlinable public func sql(encoder: PostgresDataEncoder) -> any SQLDatabase { self.sql(encoder: encoder, decoder: .init()) }
    @inlinable public func sql(decoder: PostgresDataDecoder) -> any SQLDatabase { self.sql(encoder: .init(), decoder: decoder) }
    @inlinable public func sql(encoder: PostgresDataEncoder, decoder: PostgresDataDecoder) -> any SQLDatabase {
        self.sql(
            encodingContext: .init(jsonEncoder: TypeErasedPostgresJSONEncoder(json: encoder.json)),
            decodingContext: .init(jsonDecoder: TypeErasedPostgresJSONDecoder(json: decoder.json))
        )
    }
}

extension PostgresRow {
    @available(*, deprecated, message: "Use `.sql(jsonDecoder:)` instead.")
    @inlinable public func sql(decoder: PostgresDataDecoder) -> any SQLRow {
        self.sql(decodingContext: .init(jsonDecoder: TypeErasedPostgresJSONDecoder(json: decoder.json)))
    }
}

@usableFromInline
struct TypeErasedPostgresJSONDecoder: PostgresJSONDecoder {
    let json: any PostgresJSONDecoder
    @usableFromInline init(json: any PostgresJSONDecoder) { self.json = json }
    @usableFromInline func decode<T: Decodable>(_: T.Type, from data: Data) throws -> T { try self.json.decode(T.self, from: data) }
    @usableFromInline func decode<T: Decodable>(_: T.Type, from buffer: ByteBuffer) throws -> T { try self.json.decode(T.self, from: buffer) }
}

@usableFromInline
struct TypeErasedPostgresJSONEncoder: PostgresJSONEncoder {
    let json: any PostgresJSONEncoder
    @usableFromInline init(json: any PostgresJSONEncoder) { self.json = json }
    @usableFromInline func encode<T: Encodable>(_ value: T) throws -> Data { try self.json.encode(value) }
    @usableFromInline func encode<T: Encodable>(_ value: T, into buffer: inout ByteBuffer) throws { try self.json.encode(value, into: &buffer) }
}

