/// Internal `UnkeyedDecodingContainer` for `CodableDataDecoder`
final class CodableDataUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    /// See `UnkeyedDecodingContainer.count`
    var count: Int?

    /// See `UnkeyedDecodingContainer.isAtEnd`
    var isAtEnd: Bool {
        return currentIndex == count
    }

    /// See `UnkeyedDecodingContainer.currentIndex`
    var currentIndex: Int

    /// Creates a coding key for the current index, then increments the count.
    var index: CodingKey {
        defer { currentIndex += 1}
        return CodableDataArrayKey(currentIndex)
    }

    /// See `UnkeyedDecodingContainer.codingPath`
    var codingPath: [CodingKey]

    /// Data being encoded.
    let partialData: PartialCodableData

    /// Creates a new internal `CodableDataUnkeyedDecodingContainer`.
    init(partialData: PartialCodableData, at path: [CodingKey]) {
        self.codingPath = path
        self.partialData = partialData
        switch partialData.get(at: codingPath) {
        case .some(let w):
            switch w {
            case .array(let a): count = a.count
            default: count = nil
            }
        case .none: count = nil
        }
        currentIndex = 0
    }

    /// See `UnkeyedDecodingContainer.decodeNil`
    func decodeNil() throws -> Bool {
        return partialData.decodeNil(at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.decode`
    func decode(_ type: Bool.Type) throws -> Bool {
        return try partialData.decodeBool(at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.decode`
    func decode(_ type: Int.Type) throws -> Int {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.decode`
    func decode(_ type: Int8.Type) throws -> Int8 {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.decode`
    func decode(_ type: Int16.Type) throws -> Int16 {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.decode`
    func decode(_ type: Int32.Type) throws -> Int32 {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.decode`
    func decode(_ type: Int64.Type) throws -> Int64 {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.decode`
    func decode(_ type: UInt.Type) throws -> UInt {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.decode`
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.decode`
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.decode`
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.decode`
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try partialData.decodeFixedWidthInteger(at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.decode`
    func decode(_ type: Float.Type) throws -> Float {
        return try partialData.decodeFloatingPoint(at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.decode`
    func decode(_ type: Double.Type) throws -> Double {
        return try partialData.decodeFloatingPoint(at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.decode`
    func decode(_ type: String.Type) throws -> String {
        return try partialData.decodeString(at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.decode`
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        return try partialData.decode(at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.nestedContainer`
    func nestedContainer<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key>
        where Key: CodingKey
    {
        let container = CodableDataKeyedDecodingContainer<Key>(partialData: partialData, at: codingPath + [index])
        return .init(container)
    }

    /// See `UnkeyedDecodingContainer.nestedUnkeyedContainer`
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return CodableDataUnkeyedDecodingContainer(partialData: partialData, at: codingPath + [index])
    }

    /// See `UnkeyedDecodingContainer.superDecoder`
    func superDecoder() throws -> Decoder {
        return _CodableDataDecoder(partialData: partialData, at: codingPath + [index])
    }
}

