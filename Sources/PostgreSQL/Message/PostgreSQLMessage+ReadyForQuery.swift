extension PostgreSQLMessage {
    /// Identifies the message type. ReadyForQuery is sent whenever the backend is ready for a new query cycle.
    struct ReadyForQuery {
        /// Current backend transaction status indicator.
        /// Possible values are 'I' if idle (not in a transaction block);
        /// 'T' if in a transaction block; or 'E' if in a failed transaction block
        /// (queries will be rejected until block is ended).
        var transactionStatus: UInt8
    }
}

// MARK: String

extension PostgreSQLMessage.ReadyForQuery: CustomStringConvertible {
    /// See `CustomStringConvertible`.
    var description: String {
        let char = String(bytes: [transactionStatus], encoding: .ascii) ?? "n/a"
        return "transactionStatus: \(char)"
    }
}


// MARK: Parse

extension PostgreSQLMessage.ReadyForQuery {
    /// Parses an instance of this message type from a byte buffer.
    static func parse(from buffer: inout ByteBuffer) throws -> PostgreSQLMessage.ReadyForQuery {
        guard let status = buffer.readInteger(as: UInt8.self) else {
            throw PostgreSQLError.protocol(reason: "Could not read transaction status from ready for query message.")
        }
        return .init(transactionStatus: status)
    }
}
