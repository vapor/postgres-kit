extension PostgreSQLMessage {
    /// Identifies the message as a Bind command.
    struct BindRequest {
        /// The name of the destination portal (an empty string selects the unnamed portal).
        var portalName: String
        
        /// The name of the source prepared statement (an empty string selects the unnamed prepared statement).
        var statementName: String
        
        /// The number of parameter format codes that follow (denoted C below).
        /// This can be zero to indicate that there are no parameters or that the parameters all use the default format (text);
        /// or one, in which case the specified format code is applied to all parameters; or it can equal the actual number of parameters.
        /// The parameter format codes. Each must presently be zero (text) or one (binary).
        var parameterFormatCodes: [FormatCode]
        
        /// The number of parameter values that follow (possibly zero). This must match the number of parameters needed by the query.
        var parameters: [Parameter]
        
        /// The number of result-column format codes that follow (denoted R below).
        /// This can be zero to indicate that there are no result columns or that the result columns should all use the default format (text);
        /// or one, in which case the specified format code is applied to all result columns (if any);
        /// or it can equal the actual number of result columns of the query.
        var resultFormatCodes: [FormatCode]
    }
}

// MARK: Parameter

extension PostgreSQLMessage.BindRequest {
    struct Parameter {
        /// The value of the parameter, in the format indicated by the associated format code. n is the above length.
        var data: Data?
    }
}

// MARK: Serialize

extension PostgreSQLMessage.BindRequest {
    /// Serializes this message into a byte buffer.
    func serialize(into buffer: inout ByteBuffer) {
        buffer.write(nullTerminated: portalName)
        buffer.write(nullTerminated: statementName)
        buffer.write(array: parameterFormatCodes.map { $0.rawValue })
        buffer.write(array: parameters) { buffer, parameter in
            if let data = parameter.data {
                // The length of the parameter value, in bytes (this count does not include itself). Can be zero.
                buffer.write(integer: numericCast(data.count), as: Int32.self)
                // The value of the parameter, in the format indicated by the associated format code. n is the above length.
                buffer.write(bytes: data)
            } else {
                // As a special case, -1 indicates a NULL parameter value. No value bytes follow in the NULL case.
                buffer.write(integer: -1, as: Int32.self)
            }
        }
        // After the last parameter, the following fields appear:
        buffer.write(array: resultFormatCodes.map { $0.rawValue })
    }
}
