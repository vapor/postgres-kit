/// Internal `SingleValueDecodingContainer` for `CodableDataDecoder`
final class CodableDataSingleValueDecodingContainer: SingleValueDecodingContainer {
    /// See `SingleValueDecodingContainer.codingPath`
    var codingPath: [CodingKey]

    /// Data being encoded.
    let partialData: PartialCodableData

    /// Creates a new internal `CodableDataSingleValueDecodingContainer`.
    init(partialData: PartialCodableData, at path: [CodingKey]) {
        self.codingPath = path
        self.partialData = partialData
    }

    /// See `SingleValueDecodingContainer.decodeNil`
    func decodeNil() -> Bool {
        return partialData.get(at: codingPath) == nil
    }

    /// See `SingleValueDecodingContainer.decode`
    func decode(_ type: Bool.Type) throws -> Bool {
        return try partialData.decodeBool(at: codingPath)
    }

    /// See `SingleValueDecodingContainer.decode`
    func decode(_ type: Int.Type) throws -> Int {
        return try partialData.decodeFixedWidthInteger(at: codingPath)
    }

    /// See `SingleValueDecodingContainer.decode`
    func decode(_ type: Int8.Type) throws -> Int8 {
        return try partialData.decodeFixedWidthInteger(at: codingPath)
    }

    /// See `SingleValueDecodingContainer.decode`
    func decode(_ type: Int16.Type) throws -> Int16 {
        return try partialData.decodeFixedWidthInteger(at: codingPath)
    }

    /// See `SingleValueDecodingContainer.decode`
    func decode(_ type: Int32.Type) throws -> Int32 {
        return try partialData.decodeFixedWidthInteger(at: codingPath)
    }

    /// See `SingleValueDecodingContainer.decode`
    func decode(_ type: Int64.Type) throws -> Int64 {
        return try partialData.decodeFixedWidthInteger(at: codingPath)
    }

    /// See `SingleValueDecodingContainer.decode`
    func decode(_ type: UInt.Type) throws -> UInt {
        return try partialData.decodeFixedWidthInteger(at: codingPath)
    }

    /// See `SingleValueDecodingContainer.decode`
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try partialData.decodeFixedWidthInteger(at: codingPath)
    }

    /// See `SingleValueDecodingContainer.decode`
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try partialData.decodeFixedWidthInteger(at: codingPath)
    }

    /// See `SingleValueDecodingContainer.decode`
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try partialData.decodeFixedWidthInteger(at: codingPath)
    }

    /// See `SingleValueDecodingContainer.decode`
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try partialData.decodeFixedWidthInteger(at: codingPath)
    }

    /// See `SingleValueDecodingContainer.decode`
    func decode(_ type: Float.Type) throws -> Float {
        return try partialData.decodeFloatingPoint(at: codingPath)
    }

    /// See `SingleValueDecodingContainer.decode`
    func decode(_ type: Double.Type) throws -> Double {
        return try partialData.decodeFloatingPoint(at: codingPath)
    }

    /// See `SingleValueDecodingContainer.decode`
    func decode(_ type: String.Type) throws -> String {
        return try partialData.decodeString(at: codingPath)
    }

    /// See `SingleValueDecodingContainer.decode`
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        return try partialData.decode(at: codingPath)
    }

    /// See `SingleValueDecodingContainer.nestedContainer`
    func nestedContainer<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key>
        where Key: CodingKey
    {
        let container = CodableDataKeyedDecodingContainer<Key>(partialData: partialData, at: codingPath)
        return .init(container)
    }

    /// See `SingleValueDecodingContainer.nestedSingleValueContainer`
    func nestedSingleValueContainer() throws -> SingleValueDecodingContainer {
        return CodableDataSingleValueDecodingContainer(partialData: partialData, at: codingPath)
    }

    /// See `SingleValueDecodingContainer.superDecoder`
    func superDecoder() throws -> Decoder {
        return _CodableDataDecoder(partialData: partialData, at: codingPath)
    }
}

