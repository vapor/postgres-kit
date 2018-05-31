import COperatingSystem
import Foundation

/// Representable by a `JSONB` column on the PostgreSQL database.
public protocol PostgreSQLJSONCustomConvertible: PostgreSQLDataConvertible { }

extension PostgreSQLJSONCustomConvertible {
    /// See `PostgreSQLDataConvertible`.
    public static var postgreSQLDataType: PostgreSQLDataType { return .jsonb }

    /// See `PostgreSQLDataConvertible`.
    public static var postgreSQLDataArrayType: PostgreSQLDataType { return ._jsonb }

    /// See `PostgreSQLDataConvertible`.
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        guard case .jsonb = data.type else {
            throw PostgreSQLError(identifier: "json", reason: "Could not decode \(Self.self) from data type: \(data.type).")
        }

        guard let decodable = Self.self as? Decodable.Type else {
            fatalError("`\(Self.self)` is not `Decodable`.")
        }

        switch data.storage {
        case .text(let value):
            let decoder = try JSONDecoder().decode(DecoderUnwrapper.self, from: value).decoder
            return try decodable.init(from: decoder) as! Self
        case .binary(let value):
            assert(value[value.startIndex] == 0x01)
            let decoder = try JSONDecoder().decode(DecoderUnwrapper.self, from: value[value.index(after: value.startIndex)...]).decoder
            return try decodable.init(from: decoder) as! Self
        case .null: throw PostgreSQLError(identifier: "data", reason: "Unable to decode \(Self.self) JSON from null.")
        }
    }

    /// See `PostgreSQLDataConvertible`.
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        guard let encodable = self as? Encodable else {
            fatalError("`\(Self.self)` is not `Encodable`.")
        }
        
        // JSONB requires version number in a first byte
        return try PostgreSQLData(.jsonb, binary: [0x01] + JSONEncoder().encode(EncoderWrapper(encodable)))
    }
}

// MARK: Private

extension Dictionary: PostgreSQLJSONCustomConvertible { }

private struct DecoderUnwrapper: Decodable {
    let decoder: Decoder
    init(from decoder: Decoder) {
        self.decoder = decoder
    }
}

private struct EncoderWrapper: Encodable {
    var encodable: Encodable
    init(_ encodable: Encodable) {
        self.encodable = encodable
    }
    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}

