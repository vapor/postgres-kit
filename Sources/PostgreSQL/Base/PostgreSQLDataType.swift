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
        case .int: return .int8
        case .uint: return .int8
        case .uint8: return .char
        case .uint16: return .int2
        case .uint32: return .int4
        case .null: return .void
        case .string: return .varchar
        case .double: return .float8
        case .float: return .float4
        case .data: return .bytea
        case .date: return .timestamp
        }
    }

    /// If true, this type supports binary format.
    var supportsBinaryFormat: Bool {
        switch self {
        case .bool: return true
        case .bytea: return true
        case .char: return true
        case .name: return true
        case .int8: return true
        case .int2: return true
        case .int4: return true
        case .regproc: return true
        case .text: return true
        case .oid: return true
        case .pg_node_tree: return false
        case .float4: return true
        case .float8: return true
        case ._aclitem: return false
        case .bpchar: return true
        case .varchar: return true
        case .date: return false
        case .time: return false
        case .timestamp: return false
        case .numeric: return false
        case .void: return true
        }
    }
}
