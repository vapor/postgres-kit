/// Encodes `Encodable` items to `PostgreSQLData`.
public final class PostgreSQLDataEncoder {
    /// Creates a new `PostgreSQLDataEncoder`.
    public init() {}

    /// Encodes the supplied `Encodable` to `PostgreSQLData`
    public func encode(_ encodable: Encodable) throws -> PostgreSQLData {
        let data = PartialPostgreSQLData(data: .null)
        let encoder = _PostgreSQLDataEncoder(partialData: data, at: [])
        try encodable.encode(to: encoder)
        return data.data
    }
}

/// Internal `Encoder` implementation for `PostgreSQLDataEncoder`.
internal final class _PostgreSQLDataEncoder: Encoder {
    /// See `Encoder.codingPath`
    var codingPath: [CodingKey]

    /// See `Encoder.codingPath`
    var userInfo: [CodingUserInfoKey: Any]

    /// Data being encoded.
    let partialData: PartialPostgreSQLData

    /// Creates a new internal `_PostgreSQLDataEncoder`.
    init(partialData: PartialPostgreSQLData, at path: [CodingKey]) {
        self.codingPath = path
        self.userInfo = [:]
        self.partialData = partialData
    }

    /// See `Encoder.container`
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = PostgreSQLDataKeyedEncodingContainer<Key>(partialData: partialData, at: codingPath)
        return .init(container)
    }

    /// See `Encoder.unkeyedContainer`
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return PostgreSQLDataUnkeyedEncodingContainer(partialData: partialData, at: codingPath)
    }

    /// See `Encoder.singleValueContainer`
    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError()
    }
}
