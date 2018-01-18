/// Encodes `Decodable` items to `PostgreSQLData`.
public final class PostgreSQLDataDecoder {
    /// Creates a new `PostgreSQLDataDecoder`.
    public init() {}

    /// Decodes the supplied `Decodable` to `PostgreSQLData`
    public func decode<D>(_ type: D.Type = D.self, from data: PostgreSQLData) throws -> D
        where D: Decodable
    {
        let decoder = _PostgreSQLDataDecoder(partialData: .init(data: data), at: [])
        return try D(from: decoder)
    }
}

/// Internal `Decoder` implementation for `PostgreSQLDataDecoder`.
internal final class _PostgreSQLDataDecoder: Decoder {
    /// See `Decoder.codingPath`
    var codingPath: [CodingKey]

    /// See `Decoder.codingPath`
    var userInfo: [CodingUserInfoKey: Any]

    /// Data being encoded.
    let partialData: PartialPostgreSQLData

    /// Creates a new internal `_PostgreSQLDataDecoder`.
    init(partialData: PartialPostgreSQLData, at path: [CodingKey]) {
        self.codingPath = path
        self.userInfo = [:]
        self.partialData = partialData
    }

    /// See `Decoder.container`
    func container<Key>(keyedBy type: Key.Type) -> KeyedDecodingContainer<Key>
        where Key: CodingKey
    {
        let container = PostgreSQLDataKeyedDecodingContainer<Key>(partialData: partialData, at: codingPath)
        return .init(container)
    }

    /// See `Decoder.unkeyedContainer`
    func unkeyedContainer() -> UnkeyedDecodingContainer {
        fatalError()
    }

    /// See `Decoder.singleValueContainer`
    func singleValueContainer() -> SingleValueDecodingContainer {
        fatalError()
    }
}

