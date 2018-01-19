/// Represents an array index.
struct CodableDataArrayKey: CodingKey {
    /// See `CodingKey.intValue`
    var intValue: Int?

    /// See `CodingKey.stringValue`
    var stringValue: String

    /// See `CodingKey.init(stringValue:)`
    init?(stringValue: String) {
        return nil
    }

    /// See `CodingKey.init(intValue:)`
    init?(intValue: Int) {
        self.init(intValue)
    }

    /// Creates a new `CodableDataArrayKey` from the supplied index.
    init(_ index: Int) {
        self.intValue = index
        self.stringValue = index.description
    }
}
