/// The data type's raw object ID.
/// Use `select * from pg_type where oid = <idhere>;` to lookup more information.
public struct PostgreSQLDataType: Codable, Equatable, ExpressibleByIntegerLiteral {
    /// Recognized types
    public static let null = PostgreSQLDataType(0)
    public static let bool = PostgreSQLDataType(16)
    public static let bytea = PostgreSQLDataType(17)
    public static let char = PostgreSQLDataType(18)
    public static let name = PostgreSQLDataType(19)
    public static let int8 = PostgreSQLDataType(20)
    public static let int2 = PostgreSQLDataType(21)
    public static let int4 = PostgreSQLDataType(23)
    public static let regproc = PostgreSQLDataType(24)
    public static let text = PostgreSQLDataType(25)
    public static let oid = PostgreSQLDataType(26)
    public static let json = PostgreSQLDataType(114)
    public static let pg_node_tree = PostgreSQLDataType(194)
    public static let point = PostgreSQLDataType(600)
    public static let float4 = PostgreSQLDataType(700)
    public static let float8 = PostgreSQLDataType(701)
    public static let _bool = PostgreSQLDataType(1000)
    public static let _bytea = PostgreSQLDataType(1001)
    public static let _char = PostgreSQLDataType(1002)
    public static let _name = PostgreSQLDataType(1003)
    public static let _int2 = PostgreSQLDataType(1005)
    public static let _int4 = PostgreSQLDataType(1007)
    public static let _text = PostgreSQLDataType(1009)
    public static let _int8 = PostgreSQLDataType(1016)
    public static let _point = PostgreSQLDataType(1017)
    public static let _float4 = PostgreSQLDataType(1021)
    public static let _float8 = PostgreSQLDataType(1022)
    public static let _aclitem = PostgreSQLDataType(1034)
    public static let bpchar = PostgreSQLDataType(1042)
    public static let varchar = PostgreSQLDataType(1043)
    public static let date = PostgreSQLDataType(1082)
    public static let time = PostgreSQLDataType(1083)
    public static let timestamp = PostgreSQLDataType(1114)
    public static let _timestamp = PostgreSQLDataType(1115)
    public static let timestamptz = PostgreSQLDataType(1184)
    public static let timetz = PostgreSQLDataType(1266)
    public static let numeric = PostgreSQLDataType(1700)
    public static let void = PostgreSQLDataType(2278)
    public static let uuid = PostgreSQLDataType(2950)
    public static let _uuid = PostgreSQLDataType(2951)
    public static let jsonb = PostgreSQLDataType(3802)
    public static let _jsonb = PostgreSQLDataType(3807)

    /// See `Equatable.==`
    public static func ==(lhs: PostgreSQLDataType, rhs: PostgreSQLDataType) -> Bool {
        return lhs.raw == rhs.raw
    }

    /// The raw data type code recognized by PostgreSQL.
    public var raw: Int32

    /// See `ExpressibleByIntegerLiteral.init(integerLiteral:)`
    public init(integerLiteral value: Int32) {
        self.init(value)
    }

    /// Creates a new `PostgreSQLDataType`
    public init(_ raw: Int32) {
        self.raw = raw
    }
}

extension PostgreSQLDataType {
    /// Returns the known SQL name, if one exists.
    /// Note: This only supports a limited subset of all PSQL types and is meant for convenience only.
    public var knownSQLName: String? {
        switch self {
        case .bool: return "BOOLEAN"
        case .bytea: return "BYTEA"
        case .char: return "CHAR"
        case .name: return "NAME"
        case .int8: return "BIGINT"
        case .int2: return "SMALLINT"
        case .int4: return "INTEGER"
        case .regproc: return "REGPROC"
        case .text: return "TEXT"
        case .oid: return "OID"
        case .json: return "JSON"
        case .pg_node_tree: return "PGNODETREE"
        case .point: return "POINT"
        case .float4: return "REAL"
        case .float8: return "DOUBLE PRECISION"
        case ._bool: return "BOOLEAN[]"
        case ._bytea: return "BYTEA[]"
        case ._char: return "CHAR[]"
        case ._name: return "NAME[]"
        case ._int2: return "SMALLINT[]"
        case ._int4: return "INTEGER[]"
        case ._text: return "TEXT[]"
        case ._int8: return "BIGINT[]"
        case ._point: return "POINT[]"
        case ._float4: return "REAL[]"
        case ._float8: return "DOUBLE PRECISION[]"
        case ._aclitem: return "ACLITEM[]"
        case .bpchar: return "BPCHAR"
        case .varchar: return "VARCHAR"
        case .date: return "DATE"
        case .time: return "TIME"
        case .timestamp: return "TIMESTAMP"
        case ._timestamp: return "TIMESTAMP[]"
        case .numeric: return "NUMERIC"
        case .void: return "VOID"
        case .uuid: return "UUID"
        case ._uuid: return "UUID[]"
        case .jsonb: return "JSONB"
        case ._jsonb: return "JSONB[]"
        default: return nil
        }
    }
    
    /// Returns the array type for this type if one is known.
    internal var arrayType: PostgreSQLDataType? {
        switch self {
        case .bool: return ._bool
        case .bytea: return ._bytea
        case .char: return ._char
        case .name: return ._name
        case .int2: return ._int2
        case .int4: return ._int4
        case .int8: return ._int8
        case .point: return ._point
        case .float4: return ._float4
        case .float8: return ._float8
        case .uuid: return ._uuid
        case .jsonb: return ._jsonb
        default: return nil
        }
    }
}

extension PostgreSQLDataType: CustomStringConvertible {
    /// See `CustomStringConvertible.description`
    public var description: String {
        return knownSQLName ?? "UNKNOWN \(raw)"
    }
}
