import COperatingSystem
import Foundation

/// Representable by a `JSONB` column on the PostgreSQL database.
public protocol PostgreSQLJSONCustomConvertible: PostgreSQLDataConvertible { }

extension PostgreSQLJSONCustomConvertible {
    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataType`
    public static var postgreSQLDataType: PostgreSQLDataType { return .jsonb }

    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataArrayType`
    public static var postgreSQLDataArrayType: PostgreSQLDataType { return ._jsonb }

    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        guard let value = data.data else {
            throw PostgreSQLError(identifier: "data", reason: "Unable to decode PostgreSQL JSON from `null` data.", source: .capture())
        }


        guard let decodable = Self.self as? Decodable.Type else {
            fatalError("`\(Self.self)` is not `Decodable`.")
        }

        switch data.type {
        case .jsonb:
            switch data.format {
            case .text:
                let decoder = try JSONDecoder().decode(DecoderUnwrapper.self, from: value).decoder
                return try decodable.init(from: decoder) as! Self
            case .binary:
                assert(value[0] == 0x01)
                let decoder = try JSONDecoder().decode(DecoderUnwrapper.self, from: value[1...]).decoder
                return try decodable.init(from: decoder) as! Self
            }
        default: throw PostgreSQLError(identifier: "json", reason: "Could not decode \(Self.self) from data type: \(data.type).", source: .capture())
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        guard let encodable = self as? Encodable else {
            fatalError("`\(Self.self)` is not `Encodable`.")
        }
        return try PostgreSQLData(
            type: .jsonb,
            format: .text,
            data: JSONEncoder().encode(EncoderWrapper(encodable))
        )
    }
}

extension Dictionary: PostgreSQLJSONCustomConvertible { }

fileprivate struct DecoderUnwrapper: Decodable {
    let decoder: Decoder
    init(from decoder: Decoder) {
        self.decoder = decoder
    }
}

fileprivate struct EncoderWrapper: Encodable {
    var encodable: Encodable
    init(_ encodable: Encodable) {
        self.encodable = encodable
    }
    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}

