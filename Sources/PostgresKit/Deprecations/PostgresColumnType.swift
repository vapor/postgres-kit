import AsyncKit
import SQLKit

/// Postgres-specific column types.
@available(*, deprecated, message: "Use `PostgresDataType` instead.")
public struct PostgresColumnType: SQLExpression, Hashable {
    public static var blob: PostgresColumnType { .varbit }

    /// signed eight-byte integer
    public static var int8: PostgresColumnType { .bigint }

    /// signed eight-byte integer
    public static var bigint: PostgresColumnType { .init(.bigint) }

    /// autoincrementing eight-byte integer
    public static var serial8: PostgresColumnType { .bigserial }

    /// autoincrementing eight-byte integer
    public static var bigserial: PostgresColumnType { .init(.bigserial) }

    /// fixed-length bit string
    public static var bit: PostgresColumnType { .init(.bit(nil)) }

    /// fixed-length bit string
    public static func bit(_ n: Int) -> PostgresColumnType { .init(.bit(n)) }

    /// variable-length bit string
    public static var varbit: PostgresColumnType { .init(.varbit(nil)) }

    /// variable-length bit string
    public static func varbit(_ n: Int) -> PostgresColumnType { .init(.varbit(n)) }

    /// logical Boolean (true/false)
    public static var bool: PostgresColumnType { .boolean }

    /// logical Boolean (true/false)
    public static var boolean: PostgresColumnType { .init(.boolean) }

    /// rectangular box on a plane
    public static var box: PostgresColumnType { .init(.box) }

    /// binary data (“byte array”)
    public static var bytea: PostgresColumnType { .init(.bytea) }

    /// fixed-length character string
    public static var char: PostgresColumnType { .init(.char(nil)) }

    /// fixed-length character string
    public static func char(_ n: Int) -> PostgresColumnType { .init(.char(n)) }

    /// variable-length character string
    public static var varchar: PostgresColumnType { .init(.varchar(nil)) }

    /// variable-length character string
    public static func varchar(_ n: Int) -> PostgresColumnType { .init(.varchar(n)) }

    /// IPv4 or IPv6 network address
    public static var cidr: PostgresColumnType { .init(.cidr) }

    /// circle on a plane
    public static var circle: PostgresColumnType { .init(.circle) }

    /// calendar date (year, month, day)
    public static var date: PostgresColumnType { .init(.date) }

    /// floating-point number (8 bytes)
    public static var float8: PostgresColumnType { .doublePrecision }

    /// floating-point number (8 bytes)
    public static var doublePrecision: PostgresColumnType { .init(.doublePrecision) }

    /// IPv4 or IPv6 host address
    public static var inet: PostgresColumnType { .init(.inet) }

    /// signed four-byte integer
    public static var int: PostgresColumnType { .integer }

    /// signed four-byte integer
    public static var int4: PostgresColumnType { .integer }

    /// signed four-byte integer
    public static var integer: PostgresColumnType { .init(.integer) }

    /// time span
    public static var interval: PostgresColumnType { .init(.interval) }

    /// textual JSON data
    public static var json: PostgresColumnType { .init(.json) }

    /// binary JSON data, decomposed
    public static var jsonb: PostgresColumnType { .init(.jsonb) }

    /// infinite line on a plane
    public static var line: PostgresColumnType { .init(.line) }

    /// line segment on a plane
    public static var lseg: PostgresColumnType { .init(.lseg) }

    /// MAC (Media Access Control) address
    public static var macaddr: PostgresColumnType { .init(.macaddr) }

    /// MAC (Media Access Control) address (EUI-64 format)
    public static var macaddr8: PostgresColumnType { .init(.macaddr8) }

    /// currency amount
    public static var money: PostgresColumnType { .init(.money) }

    /// exact numeric of selectable precision
    public static var decimal: PostgresColumnType { .init(.numeric(nil, nil)) }

    /// exact numeric of selectable precision
    public static func decimal(_ p: Int, _ s: Int) -> PostgresColumnType { .init(.numeric(p, s)) }

    /// exact numeric of selectable precision
    public static func numeric(_ p: Int, _ s: Int) -> PostgresColumnType { .init(.numeric(p, s)) }

    /// exact numeric of selectable precision
    public static var numeric: PostgresColumnType { .init(.numeric(nil, nil)) }

    /// geometric path on a plane
    public static var path: PostgresColumnType { .init(.path) }

    /// PostgreSQL Log Sequence Number
    public static var pgLSN: PostgresColumnType { .init(.pgLSN) }

    /// geometric point on a plane
    public static var point: PostgresColumnType { .init(.point) }

    /// closed geometric path on a plane
    public static var polygon: PostgresColumnType { .init(.polygon) }

    /// single precision floating-point number (4 bytes)
    public static var float4: PostgresColumnType { .real }

    /// single precision floating-point number (4 bytes)
    public static var real: PostgresColumnType { .init(.real) }

    /// signed two-byte integer
    public static var int2: PostgresColumnType { .smallint }

    /// signed two-byte integer
    public static var smallint: PostgresColumnType { .init(.smallint) }

    /// autoincrementing two-byte integer
    public static var serial2: PostgresColumnType { .smallserial }

    /// autoincrementing two-byte integer
    public static var smallserial: PostgresColumnType { .init(.smallserial) }

    /// autoincrementing four-byte integer
    public static var serial4: PostgresColumnType { .serial }

    /// autoincrementing four-byte integer
    public static var serial: PostgresColumnType { .init(.serial) }

    /// variable-length character string
    public static var text: PostgresColumnType { .init(.text) }

    /// time of day (no time zone)
    public static var time: PostgresColumnType { .init(.time(nil)) }

    /// time of day (no time zone)
    public static func time(_ n: Int) -> PostgresColumnType { .init(.time(n)) }

    /// time of day, including time zone
    public static var timetz: PostgresColumnType { .init(.timetz(nil)) }

    /// time of day, including time zone
    public static func timetz(_ n: Int) -> PostgresColumnType { .init(.timetz(n)) }

    /// date and time (no time zone)
    public static var timestamp: PostgresColumnType { .init(.timestamp(nil)) }

    /// date and time (no time zone)
    public static func timestamp(_ n: Int) -> PostgresColumnType { .init(.timestamp(n)) }

    /// date and time, including time zone
    public static var timestamptz: PostgresColumnType { .init(.timestamptz(nil)) }

    /// date and time, including time zone
    public static func timestamptz(_ n: Int) -> PostgresColumnType { .init(.timestamptz(n)) }

    /// text search query
    public static var tsquery: PostgresColumnType { .init(.tsquery) }

    /// text search document
    public static var tsvector: PostgresColumnType { .init(.tsvector) }

    /// user-level transaction ID snapshot
    public static var txidSnapshot: PostgresColumnType { .init(.txidSnapshot) }

    /// universally unique identifier
    public static var uuid: PostgresColumnType { .init(.uuid) }

    /// XML data
    public static var xml: PostgresColumnType { .init(.xml) }

    /// User-defined type
    public static func custom(_ name: String) -> PostgresColumnType { .init(.custom(name)) }

    /// Creates an array type from a `PostgreSQLDataType`.
    public static func array(_ type: PostgresColumnType) -> PostgresColumnType { .init(.array(of: type.primitive)) }

    private let primitive: Primitive
    private init(_ primitive: Primitive) { self.primitive = primitive }

    enum Primitive: CustomStringConvertible, Hashable {
        case bigint /// signed eight-byte integer
        case bigserial /// autoincrementing eight-byte integer
        case bit(Int?) /// fixed-length bit string
        case varbit(Int?) /// variable-length bit string
        case boolean /// logical Boolean (true/false)
        case box /// rectangular box on a plane
        case bytea /// binary data (“byte array”)
        case char(Int?) /// fixed-length character string
        case varchar(Int?) /// variable-length character string
        case cidr /// IPv4 or IPv6 network address
        case circle /// circle on a plane
        case date /// calendar date (year, month, day)
        case doublePrecision /// floating-point number (8 bytes)
        case inet /// IPv4 or IPv6 host address
        case integer /// signed four-byte integer
        case interval /// time span
        case json /// textual JSON data
        case jsonb /// binary JSON data, decomposed
        case line /// infinite line on a plane
        case lseg /// line segment on a plane
        case macaddr /// MAC (Media Access Control) address
        case macaddr8 /// MAC (Media Access Control) address (EUI-64 format)
        case money /// currency amount
        case numeric(Int?, Int?) /// exact numeric of selectable precision
        case path /// geometric path on a plane
        case pgLSN /// PostgreSQL Log Sequence Number
        case point /// geometric point on a plane
        case polygon /// closed geometric path on a plane
        case real /// single precision floating-point number (4 bytes)
        case smallint /// signed two-byte integer
        case smallserial /// autoincrementing two-byte integer
        case serial /// autoincrementing four-byte integer
        case text /// variable-length character string
        case time(Int?) /// time of day (no time zone)
        case timetz(Int?) /// time of day, including time zone
        case timestamp(Int?) /// date and time (no time zone)
        case timestamptz(Int?) /// date and time, including time zone
        case tsquery /// text search query
        case tsvector /// text search document
        case txidSnapshot /// user-level transaction ID snapshot
        case uuid /// universally unique identifier
        case xml /// XML data
        case custom(String) /// User-defined type
        indirect case array(of: Primitive) /// Array

        /// See ``Swift/CustomStringConvertible/description``.
        var description: String {
            switch self {
            case .bigint: return "BIGINT"
            case .bigserial: return "BIGSERIAL"
            case .varbit(let n): return n.map { "VARBIT(\($0))" } ?? "VARBIT"
            case .varchar(let n): return n.map { "VARCHAR(\($0))" } ?? "VARCHAR"
            case .bit(let n): return n.map { "BIT(\($0))" } ?? "BIT"
            case .boolean: return "BOOLEAN"
            case .box: return "BOX"
            case .bytea: return "BYTEA"
            case .char(let n): return n.map { "CHAR(\($0))" } ?? "CHAR"
            case .cidr: return "CIDR"
            case .circle: return "CIRCLE"
            case .date: return "DATE"
            case .doublePrecision: return "DOUBLE PRECISION"
            case .inet: return "INET"
            case .integer: return "INTEGER"
            case .interval: return "INTERVAL"
            case .json: return "JSON"
            case .jsonb: return "JSONB"
            case .line: return "LINE"
            case .lseg: return "LSEG"
            case .macaddr: return "MACADDR"
            case .macaddr8: return "MACADDER8"
            case .money: return "MONEY"
            case .numeric(let s, let p): return strictMap(s, p) { "NUMERIC(\($0), \($1))" } ?? "NUMERIC"
            case .path: return "PATH"
            case .pgLSN: return "PG_LSN"
            case .point: return "POINT"
            case .polygon: return "POLYGON"
            case .real: return "REAL"
            case .smallint: return "SMALLINT"
            case .smallserial: return "SMALLSERIAL"
            case .serial: return "SERIAL"
            case .text: return "TEXT"
            case .time(let p): return p.map { "TIME(\($0))" } ?? "TIME"
            case .timetz(let p): return p.map { "TIMETZ(\($0))" } ?? "TIMETZ"
            case .timestamp(let p): return p.map { "TIMESTAMP(\($0))" } ?? "TIMESTAMP"
            case .timestamptz(let p):  return p.map { "TIMESTAMPTZ(\($0))" } ?? "TIMESTAMPTZ"
            case .tsquery: return "TSQUERY"
            case .tsvector: return "TSVECTOR"
            case .txidSnapshot: return "TXID_SNAPSHOT"
            case .uuid: return "UUID"
            case .xml: return "XML"
            case .custom(let custom): return custom
            case .array(let element): return "\(element)[]"
            }
        }
    }

    /// See ``SQLExpression/serialize(to:)``.
    public func serialize(to serializer: inout SQLSerializer) {
        serializer.write(self.primitive.description)
    }
}
