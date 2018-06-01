extension PostgreSQLMessage {
    /// Identifies the message as a row description.
    struct RowDescription {
        /// Describes a single field returns in a `RowDescription` message.
        struct Field {
            /// The field name.
            var name: String
            
            /// If the field can be identified as a column of a specific table, the object ID of the table; otherwise zero.
            var tableObjectID: UInt32
            
            /// If the field can be identified as a column of a specific table, the attribute number of the column; otherwise zero.
            var columnAttributeNumber: Int16
            
            /// The object ID of the field's data type.
            var dataType: PostgreSQLDataType
            
            /// The data type size (see pg_type.typlen). Note that negative values denote variable-width types.
            var dataTypeSize: Int16
            
            /// The type modifier (see pg_attribute.atttypmod). The meaning of the modifier is type-specific.
            var dataTypeModifier: Int32
            
            /// The format code being used for the field.
            /// Currently will be zero (text) or one (binary).
            /// In a RowDescription returned from the statement variant of Describe,
            /// the format code is not yet known and will always be zero.
            var formatCode: FormatCode
        }
        
        /// The fields supplied in the row description.
        var fields: [Field]
    }
}

// MARK: Parse

extension PostgreSQLMessage.RowDescription {
    /// Parses an instance of this message type from a byte buffer.
    static func parse(from buffer: inout ByteBuffer) throws -> PostgreSQLMessage.RowDescription {
        guard let fields = try buffer.readArray(Field.self, { buffer in
            guard let name = buffer.readNullTerminatedString() else {
                throw PostgreSQLError.protocol(reason: "Could not read row description field name.")
            }
            guard let tableOID = buffer.readInteger(as: UInt32.self) else {
                throw PostgreSQLError.protocol(reason: "Could not read row description field table OID.")
            }
            guard let columnAttributeNumber = buffer.readInteger(as: Int16.self) else {
                throw PostgreSQLError.protocol(reason: "Could not read row description field column attribute number.")
            }
            guard let dataType = buffer.readInteger(as: Int32.self).flatMap(PostgreSQLDataType.init(_:)) else {
                throw PostgreSQLError.protocol(reason: "Could not read row description field data type.")
            }
            guard let dataTypeSize = buffer.readInteger(as: Int16.self) else {
                throw PostgreSQLError.protocol(reason: "Could not read row description field data type size.")
            }
            guard let dataTypeModifier = buffer.readInteger(as: Int32.self) else {
                throw PostgreSQLError.protocol(reason: "Could not read row description field data type modifier.")
            }
            guard let formatCode = buffer.readEnum(PostgreSQLMessage.FormatCode.self) else {
                throw PostgreSQLError.protocol(reason: "Could not read row description field format code.")
            }
            return .init(name: name, tableObjectID: tableOID, columnAttributeNumber: columnAttributeNumber, dataType: dataType, dataTypeSize: dataTypeSize, dataTypeModifier: dataTypeModifier, formatCode: formatCode)
        }) else {
            throw PostgreSQLError.protocol(reason: "Could not read row description fields.")
        }
        return .init(fields: fields)
    }
}

// MARK: Convenience

extension PostgreSQLMessage.RowDescription {
    /// Parses a `PostgreSQLDataRow` using the metadata from this row description.
    /// Important to pass formatCodes in since the format codes in the field are likely not correct (if from a describe request)
    func parse(data: PostgreSQLMessage.DataRow, formatCodes: [PostgreSQLMessage.FormatCode]) throws -> [PostgreSQLColumn: PostgreSQLData] {
        return try .init(uniqueKeysWithValues: fields.enumerated().map { (i, field) in
            let formatCode: PostgreSQLMessage.FormatCode
            switch formatCodes.count {
            case 0: formatCode = .text
            case 1: formatCode = formatCodes[0]
            default: formatCode = formatCodes[i]
            }
            let key = PostgreSQLColumn(tableOID: field.tableObjectID, name: field.name)
            let value = try data.columns[i].parse(dataType: field.dataType, format: formatCode)
            return (key, value)
        })
    }
}

extension PostgreSQLMessage.DataRow.Column {
    /// Parses this column to the specified data type and format code.
    func parse(dataType: PostgreSQLDataType, format: PostgreSQLMessage.FormatCode) throws -> PostgreSQLData {
        guard let value = value else {
            return .null
        }
        
        switch format {
        case .binary: return PostgreSQLData(dataType, binary: value)
        case .text:
            guard let string = String(data: value, encoding: .utf8) else {
                throw PostgreSQLError(identifier: "utf8", reason: "Invalid UTF8 string: \(value)")
            }
            return PostgreSQLData(dataType, text: string)
        }
    }
}
