extension PostgreSQLMessage {
    struct Notification {
        /// The message coming from PSQL
        let processID: Int32
        
        /// The name of the channel that the notify has been raised on.
        let channel: String
        
        /// The "payload" string passed from the notifying process.
        let message: String
    }
}

// MARK: Parse

extension PostgreSQLMessage.Notification {
    /// Parses an instance of this message type from a byte buffer.
    static func parse(from buffer: inout ByteBuffer) throws -> PostgreSQLMessage.Notification {
        guard let processID = buffer.readInteger(as: Int32.self) else {
            throw PostgreSQLError.protocol(reason: "Could not read process ID from notification response.")
        }
        guard let channel = buffer.readNullTerminatedString() else {
            throw PostgreSQLError.protocol(reason: "Could not read channel from notification response.")
        }
        guard let message = buffer.readNullTerminatedString() else {
            throw PostgreSQLError.protocol(reason: "Could not read message from notification response.")
        }
        return .init(processID: processID, channel: channel, message: message)
    }
}
