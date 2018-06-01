import Bits

extension PostgreSQLMessage {
    /// Identifies the message as a data row.
    struct DataRow: Decodable {
        struct Column: Decodable {
            /// The length of the column value, in bytes (this count does not include itself).
            /// Can be zero. As a special case, -1 indicates a NULL column value. No value bytes follow in the NULL case.
            
            /// The value of the column, in the format indicated by the associated format code. n is the above length.
            var value: Data?
        }

        /// The data row's columns
        var columns: [Column]
    }
}

// MARK: String

extension PostgreSQLMessage.DataRow.Column: CustomStringConvertible {
    /// See `CustomStringConvertible`.
    var description: String {
        if let value = value {
            return "0x" + value.hexEncodedString()
        } else {
            return "<null>"
        }
    }
}

extension PostgreSQLMessage.DataRow: CustomStringConvertible {
    /// See `CustomStringConvertible`.
    var description: String {
        return "Columns(" + columns.map { $0.description }.joined(separator: ", ") + ")"
    }
}

// MARK: Parse

extension PostgreSQLMessage.DataRow {
    /// Parses an instance of this message type from a byte buffer.
    static func parse(from buffer: inout ByteBuffer) throws -> PostgreSQLMessage.DataRow {
        guard let columns = buffer.readArray(Column.self, { buffer in
            return .init(value: buffer.readNullableData())
        }) else {
            throw PostgreSQLError.protocol(reason: "Could not parse data row columns.")
        }
        return .init(columns: columns)
    }
}
