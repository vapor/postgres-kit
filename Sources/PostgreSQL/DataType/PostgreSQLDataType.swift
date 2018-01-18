import Foundation

/// The data type's raw object ID.
/// Use `select * from pg_type where oid = <idhere>;` to lookup more information.
public struct PostgreSQLDataType: Codable, Equatable {
    /// Recognized types

    public static let bool = PostgreSQLDataType(raw: 16)
    public static let bytea = PostgreSQLDataType(raw: 17)
    public static let char = PostgreSQLDataType(raw: 18)
    public static let name = PostgreSQLDataType(raw: 19)
    public static let int8 = PostgreSQLDataType(raw: 20)
    public static let int2 = PostgreSQLDataType(raw: 21)
    public static let int4 = PostgreSQLDataType(raw: 23)
    public static let regproc = PostgreSQLDataType(raw: 24)
    public static let text = PostgreSQLDataType(raw: 25)
    public static let oid = PostgreSQLDataType(raw: 26)
    public static let pg_node_tree = PostgreSQLDataType(raw: 194)
    public static let point = PostgreSQLDataType(raw: 600)
    public static let float4 = PostgreSQLDataType(raw: 700)
    public static let float8 = PostgreSQLDataType(raw: 701)
    public static let _aclitem = PostgreSQLDataType(raw: 1034)
    public static let bpchar = PostgreSQLDataType(raw: 1042)
    public static let varchar = PostgreSQLDataType(raw: 1043)
    public static let date = PostgreSQLDataType(raw: 1082)
    public static let time = PostgreSQLDataType(raw: 1083)
    public static let timestamp = PostgreSQLDataType(raw: 1114)
    public static let numeric = PostgreSQLDataType(raw: 1700)
    public static let void = PostgreSQLDataType(raw: 2278)

    /// See `Equatable.==`
    public static func ==(lhs: PostgreSQLDataType, rhs: PostgreSQLDataType) -> Bool {
        return lhs.raw == rhs.raw
    }

    /// The raw data type code recognized by PostgreSQL.
    public var raw: Int32

    /// Creates a new `PostgreSQLDataType`
    public init(raw: Int32) {
        self.raw = raw
    }
}

extension PostgreSQLDataType {
    /// Converts the supplied `PostgreSQLData` to the best matching `PostgreSQLDataType`
    static func type(forData data: PostgreSQLData) -> PostgreSQLDataType {
        switch data {
        case .bool: return .bool
        case .int8: return .char
        case .int16: return .int2
        case .int32: return .int4
        case .int64: return .int8
        case .null: return .void
        case .string: return .text
        case .double: return .float8
        case .float: return .float4
        case .data: return .bytea
        case .date: return .timestamp
        case .point: return .point
        case .dictionary: fatalError("Unsupported \(#function) for dictionary")
        case .array: fatalError("Unsupported \(#function) for array")
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

        // If we don't recognize, default to text
        default: return .text
        }
    }
}
