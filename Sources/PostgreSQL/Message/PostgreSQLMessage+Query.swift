extension PostgreSQLMessage {
    /// Identifies the message as a simple query.
    struct Query {
        /// The query string itself.
        var query: String
    }

}

// MARK: Serialize

extension PostgreSQLMessage.Query {
    /// Serializes this message into a byte buffer.
    func serialize(into buffer: inout ByteBuffer) {
        buffer.write(nullTerminated: query)
    }
}
