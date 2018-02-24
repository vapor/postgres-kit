/// Represents [String: String] parameters encoded
/// as a list of strings separated by null terminators
/// and finished by a single null terminator.
struct PostgreSQLParameters: Codable, ExpressibleByDictionaryLiteral {
    /// The internal parameter storage.
    var storage: [String: String]

    /// See Encodable.encode
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        for (key, val) in storage {
            try container.encode(key)
            try container.encode(val)
        }
        try container.encode("")
    }

    /// See ExpressibleByDictionaryLiteral.init
    init(dictionaryLiteral elements: (String, String)...) {
        var storage = [String: String]()
        for (key, val) in elements {
            storage[key] = val
        }
        self.storage = storage
    }
}

