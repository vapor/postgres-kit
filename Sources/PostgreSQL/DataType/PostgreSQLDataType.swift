import Foundation

/// The data type's raw object ID.
/// Use `select * from pg_type where oid = <idhere>;` to lookup more information.
public struct PostgreSQLDataType: Codable, Equatable {
    /// Recognized types
    public static let bool = PostgreSQLDataType(raw: 16, sql: "BOOLEAN")
    public static let bytea = PostgreSQLDataType(raw: 17, sql: "BYTEA")
    public static let char = PostgreSQLDataType(raw: 18, sql: "CHAR")
    public static let name = PostgreSQLDataType(raw: 19, sql: "NAME")
    public static let int8 = PostgreSQLDataType(raw: 20, sql: "BIGINT")
    public static let int2 = PostgreSQLDataType(raw: 21, sql: "SMALLINT")
    public static let int4 = PostgreSQLDataType(raw: 23, sql: "INTEGER")
    public static let regproc = PostgreSQLDataType(raw: 24, sql: "REGPROC")
    public static let text = PostgreSQLDataType(raw: 25, sql: "TEXT")
    public static let oid = PostgreSQLDataType(raw: 26, sql: "OID")
    public static let json = PostgreSQLDataType(raw: 114, sql: "JSON")
    public static let pg_node_tree = PostgreSQLDataType(raw: 194, sql: "PGNODETREE")
    public static let point = PostgreSQLDataType(raw: 600, sql: "POINT")
    public static let float4 = PostgreSQLDataType(raw: 700, sql: "REAL")
    public static let float8 = PostgreSQLDataType(raw: 701, sql: "DOUBLE PRECISION")
    public static let _bool = PostgreSQLDataType(raw: 1000, sql: "BOOLEAN[]")
    public static let _bytea = PostgreSQLDataType(raw: 1001, sql: "BYTEA[]")
    public static let _char = PostgreSQLDataType(raw: 1002, sql: "CHAR[]")
    public static let _name = PostgreSQLDataType(raw: 1003, sql: "NAME[]")
    public static let _int2 = PostgreSQLDataType(raw: 1005, sql: "SMALLINT[]")
    public static let _int4 = PostgreSQLDataType(raw: 1007, sql: "INTEGER[]")
    public static let _text = PostgreSQLDataType(raw: 1009, sql: "TEXT[]")
    public static let _int8 = PostgreSQLDataType(raw: 1016, sql: "BIGINT[]")
    public static let _point = PostgreSQLDataType(raw: 1017, sql: "POINT[]")
    public static let _float4 = PostgreSQLDataType(raw: 1021, sql: "REAL[]")
    public static let _float8 = PostgreSQLDataType(raw: 1022, sql: "DOUBLE PRECISION[]")
    public static let _aclitem = PostgreSQLDataType(raw: 1034, sql: "ACLITEM[]")
    public static let bpchar = PostgreSQLDataType(raw: 1042, sql: "BPCHAR")
    public static let varchar = PostgreSQLDataType(raw: 1043, sql: "VARCHAR")
    public static let date = PostgreSQLDataType(raw: 1082, sql: "DATE")
    public static let time = PostgreSQLDataType(raw: 1083, sql: "TIME")
    public static let timestamp = PostgreSQLDataType(raw: 1114, sql: "TIMESTAMP")
    public static let _timestamp = PostgreSQLDataType(raw: 1115, sql: "TIMESTAMP[]")
    public static let numeric = PostgreSQLDataType(raw: 1700, sql: "NUMERIC")
    public static let void = PostgreSQLDataType(raw: 2278, sql: "VOID")
    public static let uuid = PostgreSQLDataType(raw: 2950, sql: "UUID")
    public static let _uuid = PostgreSQLDataType(raw: 2951, sql: "UUID[]")
    public static let jsonb = PostgreSQLDataType(raw: 3802, sql: "JSONB")
    public static let _jsonb = PostgreSQLDataType(raw: 3807, sql: "JSONB[]")

    /// See `Equatable.==`
    public static func ==(lhs: PostgreSQLDataType, rhs: PostgreSQLDataType) -> Bool {
        return lhs.raw == rhs.raw
    }

    /// The raw data type code recognized by PostgreSQL.
    public var raw: Int32

    /// The associated SQL string
    public let sql: String?

    /// See `Decodable.init(from:)`
    public init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        raw = try single.decode(Int32.self)
        sql = nil
    }

    /// See `Encodable.encode(to:)`
    public func encode(to encoder: Encoder) throws {
        var single = encoder.singleValueContainer()
        try single.encode(raw)
    }

    /// Creates a new `PostgreSQLDataType`
    public init(raw: Int32, sql: String) {
        self.raw = raw
        self.sql = sql
    }
}

extension PostgreSQLDataType: CustomStringConvertible {
    /// See `CustomStringConvertible.description`
    public var description: String {
        return sql ?? "UNKNOWN"
    }
}
