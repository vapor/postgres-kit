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
    public static let json = PostgreSQLDataType(raw: 114)
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
    public static let uuid = PostgreSQLDataType(raw: 2950)
    public static let jsonb = PostgreSQLDataType(raw: 3802)

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
    /// The SQL name for this data type, i.e., `"INTEGER"` for `.int4`
    public var sqlName: String {
        let string: String
        switch self {
        case .bool: string = "BOOLEAN"
        case .bytea: string = "BYTEA"
        case .char: string = "CHAR"
        case .int8: string = "BIGINT"
        case .int2: string = "SMALLINT"
        case .int4, .oid, .regproc: string = "INTEGER"
        case .text, .name: string = "TEXT"
        case .point: string = "POINT"
        case .float4: string = "REAL"
        case .float8: string = "DOUBLE PRECISION"
        case ._aclitem: string = "_aclitem"
        case .bpchar: string = "BPCHAR"
        case .varchar: string = "VARCHAR"
        case .date: string = "DATE"
        case .time: string = "TIME"
        case .timestamp: string = "TIMESTAMP"
        case .numeric: string = "NUMERIC"
        case .void: string = "VOID"
        case .uuid: string = "UUID"
        case .jsonb: string = "JSONB"
        case .json: string = "JSON"
        case .pg_node_tree: string = "pg_node_tree"
        default: string = "VOID" // FIXME: better error?
        }
        return string
    }
}

extension PostgreSQLDataType: CustomStringConvertible {
    /// See `CustomStringConvertible.description`
    public var description: String {
        return sqlName
    }
}
