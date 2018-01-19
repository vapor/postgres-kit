/// Encodes `Encodable` items to `CodableData`.
public final class CodableDataEncoder {
    /// Creates a new `CodableDataEncoder`.
    public init() {}

    /// Encodes the supplied `Encodable` to `CodableData`
    public func encode(_ encodable: Encodable) throws -> CodableData {
        let data = PartialCodableData(data: .null)
        let encoder = _CodableDataEncoder(partialData: data, at: [])
        try encodable.encode(to: encoder)
        return data.data
    }
}

/// Internal `Encoder` implementation for `CodableDataEncoder`.
internal final class _CodableDataEncoder: Encoder {
    /// See `Encoder.codingPath`
    var codingPath: [CodingKey]

    /// See `Encoder.codingPath`
    var userInfo: [CodingUserInfoKey: Any]

    /// Data being encoded.
    let partialData: PartialCodableData

    /// Creates a new internal `_CodableDataEncoder`.
    init(partialData: PartialCodableData, at path: [CodingKey]) {
        self.codingPath = path
        self.userInfo = [:]
        self.partialData = partialData
    }

    /// See `Encoder.container`
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = CodableDataKeyedEncodingContainer<Key>(partialData: partialData, at: codingPath)
        return .init(container)
    }

    /// See `Encoder.unkeyedContainer`
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return CodableDataUnkeyedEncodingContainer(partialData: partialData, at: codingPath)
    }

    /// See `Encoder.singleValueContainer`
    func singleValueContainer() -> SingleValueEncodingContainer {
        return CodableDataSingleValueEncodingContainer(partialData: partialData, at: codingPath)
    }
}

