/// Identifies the message as a simple query.
struct PostgreSQLQuery: Encodable {
    /// The query string itself.
    var query: String

    /// See Encodable.encode
    func encode(to encoder: Encoder) throws {
        var single = encoder.singleValueContainer()
        try single.encode(query)
    }
}
