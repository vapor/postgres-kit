extension PostgreSQLMessage {
    struct ParameterStatus {
        /// The name of the run-time parameter being reported.
        var parameter: String
        
        /// The current value of the parameter.
        var value: String
    }
}

// MARK: String

extension PostgreSQLMessage.ParameterStatus: CustomStringConvertible {
    /// See `CustomStringConvertible`.
    var description: String {
        return "\(parameter): \(value)"
    }
}

// MARK: Parse

extension PostgreSQLMessage.ParameterStatus {
    /// Parses an instance of this message type from a byte buffer.
    static func parse(from buffer: inout ByteBuffer) throws -> PostgreSQLMessage.ParameterStatus {
        guard let parameter = buffer.readNullTerminatedString() else {
            throw PostgreSQLError.protocol(reason: "Could not read parameter from parameter status message.")
        }
        guard let value = buffer.readNullTerminatedString() else {
            throw PostgreSQLError.protocol(reason: "Could not read value from parameter status message.")
        }
        return .init(parameter: parameter, value: value)
    }
}
