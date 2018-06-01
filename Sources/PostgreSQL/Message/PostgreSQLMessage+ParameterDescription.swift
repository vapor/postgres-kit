extension PostgreSQLMessage {
    /// Identifies the message as a parameter description.
    struct ParameterDescription {
        /// Specifies the object ID of the parameter data type.
        var dataTypes: [PostgreSQLDataType]
    }
}

// MARK: Parse

extension PostgreSQLMessage.ParameterDescription {
    /// Parses an instance of this message type from a byte buffer.
    static func parse(from buffer: inout ByteBuffer) throws -> PostgreSQLMessage.ParameterDescription {
        guard let dataTypes = try buffer.readArray(PostgreSQLDataType.self, { buffer in
            guard let raw = buffer.readInteger(as: Int32.self) else {
                throw PostgreSQLError.protocol(reason: "Could not parse data type integer in parameter description message.")
            }
            return .init(raw)
        }) else {
            throw PostgreSQLError.protocol(reason: "Could not parse data types in parameter description message.")
        }
        return .init(dataTypes: dataTypes)
    }
}
