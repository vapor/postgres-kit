/// Identifies the message as a row description.
struct PostgreSQLRowDescription: Decodable {
    /// The fields supplied in the row description.
    var fields: [PostgreSQLRowDescriptionField]

    /// See Decodable.decode
    init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()

        /// Specifies the number of fields in a row (can be zero).
        let fieldCount = try single.decode(Int16.self)
        var fields: [PostgreSQLRowDescriptionField] = []
        for _ in 0..<fieldCount {
            try fields.append(single.decode(PostgreSQLRowDescriptionField.self))
        }
        self.fields = fields
    }
}

/// MARK: Parse

extension PostgreSQLRowDescription {
    /// Parses a `PostgreSQLDataRow` using the metadata from this row description.
    public func parse(data: PostgreSQLDataRow) throws -> [String: PostgreSQLData] {
        return try .init(uniqueKeysWithValues: fields.enumerated().map { (i, field) in
                return try (field.name, data.columns[i].parse(dataType: field.dataType, format: field.formatCode))
        })
    }
}

/// MARK: Field

/// Describes a single field returns in a `RowDescription` message.
struct PostgreSQLRowDescriptionField: Decodable {
    /// The field name.
    var name: String

    /// If the field can be identified as a column of a specific table, the object ID of the table; otherwise zero.
    var tableObjectID: Int32

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
    var formatCode: PostgreSQLFormatCode
}

/// The format code being used for the field.
/// Currently will be zero (text) or one (binary).
/// In a RowDescription returned from the statement variant of Describe,
/// the format code is not yet known and will always be zero.
enum PostgreSQLFormatCode: Int16, Codable {
    case text = 0
    case binary = 1
}

/// The data type's raw object ID.
/// Use `select * from pg_type where oid in (<idhere>);` to lookup more information.
enum PostgreSQLDataType: Int32, Codable {
    case bool = 16
    case char = 18
    case name = 19
    case int2 = 21
    case int4 = 23
    case regproc = 24
    case text = 25
    case oid = 26
    case pg_node_tree = 194
    case _aclitem = 1034
}

extension PostgreSQLDataType {
    /// Converts the supplied `PostgreSQLData` to the best matching `PostgreSQLDataType`
    static func type(forData data: PostgreSQLData) -> PostgreSQLDataType {
        switch data {
        case .bool: return .int2
        case .character: return .char
        case .int8: return .char
        case .int16: return .int2
        case .int32: return .int4
        case .int: return .int4
        case .uint: return .int4
        case .uint8: return .char
        case .uint16: return .int2
        case .uint32: return .int4
        case .null: return .char // fixme
        case .string: return .char // fixme
        }
    }
}
