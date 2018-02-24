import Bits

/// Identifies the message type. ReadyForQuery is sent whenever the backend is ready for a new query cycle.
struct PostgreSQLReadyForQuery: Decodable {
    /// Current backend transaction status indicator.
    /// Possible values are 'I' if idle (not in a transaction block);
    /// 'T' if in a transaction block; or 'E' if in a failed transaction block
    /// (queries will be rejected until block is ended).
    var transactionStatus: Byte

    /// See Decodable.decode
    init(from decoder: Decoder) throws {
        self.transactionStatus = try decoder.singleValueContainer().decode(Byte.self)
    }
}

extension PostgreSQLReadyForQuery: CustomStringConvertible {
    /// CustomStringConvertible.description
    var description: String {
        let char = String(bytes: [transactionStatus], encoding: .ascii) ?? "n/a"
        return "transactionStatus: \(char)"
    }
}
