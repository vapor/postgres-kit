extension PostgreSQLMessage {
    /// Identifies the message as a Close command.
    enum CloseResponse {
        /// The name of the prepared statement or portal to close (an empty string selects the unnamed prepared statement or portal).
        case statement(name: String)
        /// The name of the prepared statement or portal to close (an empty string selects the unnamed prepared statement or portal).
        case portal(name: String)
        /// The command tag. This is usually a single word that identifies which SQL command was completed.
        case command(String)
    }
}

// MARK: Parse

extension PostgreSQLMessage.CloseResponse {
    /// Parses an instance of this message type from a byte buffer.
    static func parse(from buffer: inout ByteBuffer) throws -> PostgreSQLMessage.CloseResponse {
        guard let string = buffer.readNullTerminatedString() else {
            throw PostgreSQLError.protocol(reason: "Could not parse close response message.")
        }
        
        switch string[string.startIndex] {
        case "S": return .statement(name: .init(string[string.index(after: string.startIndex)...]))
        case "P": return .portal(name: .init(string[string.index(after: string.startIndex)...]))
        default: return .command(string)
        }
    }
}
