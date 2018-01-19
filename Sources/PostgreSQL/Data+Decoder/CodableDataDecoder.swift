/// Encodes `Decodable` items to `CodableData`.
public final class CodableDataDecoder {
    /// Creates a new `CodableDataDecoder`.
    public init() {}

    /// Decodes the supplied `Decodable` to `CodableData`
    public func decode<D>(_ type: D.Type = D.self, from data: CodableData) throws -> D
        where D: Decodable
    {
        let decoder = _CodableDataDecoder(partialData: .init(data: .null), at: [])
        return try D(from: decoder)
    }
}

/// Internal `Decoder` implementation for `CodableDataDecoder`.
internal final class _CodableDataDecoder: Decoder {
    /// See `Decoder.codingPath`
    var codingPath: [CodingKey]

    /// See `Decoder.codingPath`
    var userInfo: [CodingUserInfoKey: Any]

    /// Data being encoded.
    let partialData: PartialCodableData

    /// Creates a new internal `_CodableDataDecoder`.
    init(partialData: PartialCodableData, at path: [CodingKey]) {
        self.codingPath = path
        self.userInfo = [:]
        self.partialData = partialData
    }

    /// See `Decoder.container`
    func container<Key>(keyedBy type: Key.Type) -> KeyedDecodingContainer<Key>
        where Key: CodingKey
    {
        let container = CodableDataKeyedDecodingContainer<Key>(partialData: partialData, at: codingPath)
        return .init(container)
    }

    /// See `Decoder.unkeyedContainer`
    func unkeyedContainer() -> UnkeyedDecodingContainer {
        return CodableDataUnkeyedDecodingContainer(partialData: partialData, at: codingPath)
    }

    /// See `Decoder.singleValueContainer`
    func singleValueContainer() -> SingleValueDecodingContainer {
        return CodableDataSingleValueDecodingContainer(partialData: partialData, at: codingPath)
    }
}

