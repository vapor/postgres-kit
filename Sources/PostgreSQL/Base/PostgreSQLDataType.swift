import Foundation

/// The data type's raw object ID.
/// Use `select * from pg_type where oid = <idhere>;` to lookup more information.
enum PostgreSQLDataType: Int32, Codable {
    case bool = 16
    case bytea = 17
    case char = 18
    case name = 19
    case int8 = 20
    case int2 = 21
    case int4 = 23
    case regproc = 24
    case text = 25
    case oid = 26
    case pg_node_tree = 194
    case point = 600
    case float4 = 700
    case float8 = 701
    case _aclitem = 1034
    case bpchar = 1042
    case varchar = 1043
    case date = 1082
    case time = 1083
    case timestamp = 1114
    case numeric = 1700
    case void = 2278
}

extension PostgreSQLDataType {
    /// Converts the supplied `PostgreSQLData` to the best matching `PostgreSQLDataType`
    static func type(forData data: PostgreSQLData) -> PostgreSQLDataType {
        switch data {
        case .int8: return .char
        case .int16: return .int2
        case .int32: return .int4
        case .int64: return .int8
        case .uint64: return .int8
        case .uint8: return .bool
        case .uint16: return .int2
        case .uint32: return .int4
        case .null: return .void
        case .string: return .varchar
        case .double: return .float8
        case .float: return .float4
        case .data: return .bytea
        case .date: return .timestamp
        case .point: return .point
        }
    }
}

extension PostgreSQLDataType {
    /// This type's preferred format.
    /// Note: Ensure that the types parse and serialize support the preferred type!
    var preferredFormat: PostgreSQLFormatCode {
        switch self {
        // Binary
        // These data types will use binary format where possible
        case .bool: return .binary
        case .bytea: return .binary
        case .char: return .binary
        case .name: return .binary
        case .int8: return .binary
        case .int2: return .binary
        case .int4: return .binary
        case .regproc: return .binary
        case .text: return .binary
        case .oid: return .binary
        case .float4: return .binary
        case .float8: return .binary
        case .bpchar: return .binary
        case .varchar: return .binary
        case .void: return .binary
        case .point: return .binary

        // Text
        // Converting these to binary supporting may improve performance
        case ._aclitem: return .text
        case .pg_node_tree: return .text
        case .date: return .text
        case .time: return .text
        case .timestamp: return .text
        case .numeric: return .text
        }
    }
}
