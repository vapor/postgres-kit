public enum PostgreSQLDataType: SQLDataType {
    public static func dataType(appropriateFor type: Any.Type) -> PostgreSQLDataType? {
        guard let type = type as? PostgreSQLDataTypeStaticRepresentable.Type else {
            return nil
        }
        return type.postgreSQLDataType
    }
    
    /// signed eight-byte integer
    public static var int8: PostgreSQLDataType {
        return .bigint
    }
    
    /// signed eight-byte integer
    case bigint
    
    /// autoincrementing eight-byte integer
    public static var serial8: PostgreSQLDataType {
        return .bigserial
    }
    
    /// autoincrementing eight-byte integer
    case bigserial
    
    #if swift(>=4.2)
    /// fixed-length bit string
    public static var bit: PostgreSQLDataType {
        return .bit(nil)
    }
    #endif
    
    /// fixed-length bit string
    case bit(Int?)
    
    #if swift(>=4.2)
    /// variable-length bit string
    public static var varbit: PostgreSQLDataType {
        return .varbit(nil)
    }
    #endif
    
    /// variable-length bit string
    case varbit(Int?)
    
    /// logical Boolean (true/false)
    public static var bool: PostgreSQLDataType {
        return .boolean
    }
    
    /// logical Boolean (true/false)
    case boolean
    
    /// rectangular box on a plane
    case box
    
    /// binary data (“byte array”)
    case bytea
    
    #if swift(>=4.2)
    /// fixed-length character string
    public static var char: PostgreSQLDataType {
        return .char(nil)
    }
    #endif
    
    /// fixed-length character string
    case char(Int?)
    
    #if swift(>=4.2)
    /// variable-length character string
    public static var varchar: PostgreSQLDataType {
        return .varchar(nil)
    }
    #endif
    
    /// variable-length character string
    case varchar(Int?)
    
    /// IPv4 or IPv6 network address
    case cidr
    
    /// circle on a plane
    case circle
    
    /// calendar date (year, month, day)
    case date
    
    /// floating-point number (8 bytes)
    public static var float8: PostgreSQLDataType {
        return .doublePrecision
    }
    
    /// floating-point number (8 bytes)
    case doublePrecision
    
    /// IPv4 or IPv6 host address
    case inet
    
    /// signed four-byte integer
    public static var int: PostgreSQLDataType {
        return .integer
    }
    
    /// signed four-byte integer
    public static var int4: PostgreSQLDataType {
        return .integer
    }
    
    /// signed four-byte integer
    case integer
    
    /// time span
    case interval
    
    /// textual JSON data
    case json
    
    /// binary JSON data, decomposed
    case jsonb
    
    /// infinite line on a plane
    case line
    
    /// line segment on a plane
    case lseg
    
    /// MAC (Media Access Control) address
    case macaddr
    
    /// MAC (Media Access Control) address (EUI-64 format)
    case macaddr8
    
    /// currency amount
    case money
    
    /// exact numeric of selectable precision
    public static var decimal: PostgreSQLDataType {
        return .numeric(nil)
    }
    
    /// exact numeric of selectable precision
    public static func decimal(_ p: Int, _ s: Int) -> PostgreSQLDataType {
        return .numeric((p, s))
    }
    
    #if swift(>=4.2)
    /// exact numeric of selectable precision
    public static func numeric(_ p: Int, _ s: Int) -> DataType {
        return .numeric((p, s))
    }
    
    /// exact numeric of selectable precision
    public static var numeric: DataType {
        return .numeric(nil)
    }
    #endif
    
    /// exact numeric of selectable precision
    case numeric((Int, Int)?)
    
    /// geometric path on a plane
    case path
    
    /// PostgreSQL Log Sequence Number
    case pgLSN
    
    /// geometric point on a plane
    case point
    
    /// closed geometric path on a plane
    case polygon
    
    /// single precision floating-point number (4 bytes)
    public static var float4: PostgreSQLDataType {
        return .real
    }
    
    /// single precision floating-point number (4 bytes)
    case real
    
    /// signed two-byte integer
    public static var int2: PostgreSQLDataType {
        return .smallint
    }
    
    /// signed two-byte integer
    case smallint
    
    /// autoincrementing two-byte integer
    public static var serial2: PostgreSQLDataType {
        return .smallint
    }
    
    /// autoincrementing two-byte integer
    case smallserial
    
    /// autoincrementing four-byte integer
    public static var serial4: PostgreSQLDataType {
        return .smallint
    }
    
    /// autoincrementing four-byte integer
    case serial
    
    /// variable-length character string
    case text
    
    #if swift(>=4.2)
    /// time of day (no time zone)
    public static var time: PostgreSQLDataType {
        return .time(nil)
    }
    #endif
    
    /// time of day (no time zone)
    case time(Int?)
    
    #if swift(>=4.2)
    /// time of day, including time zone
    public static var timetz: PostgreSQLDataType {
        return .timetz(nil)
    }
    #endif
    
    /// time of day, including time zone
    case timetz(Int?)
    
    #if swift(>=4.2)
    /// date and time (no time zone)
    public static var timestamp: PostgreSQLDataType {
        return .timestamp(nil)
    }
    #endif
    
    /// date and time (no time zone)
    case timestamp(Int?)
    
    #if swift(>=4.2)
    /// date and time, including time zone
    public static var timestamptz: PostgreSQLDataType {
        return .timestamptz(nil)
    }
    #endif
    
    /// date and time, including time zone
    case timestamptz(Int?)
    
    /// text search query
    case tsquery
    
    /// text search document
    case tsvector
    
    /// user-level transaction ID snapshot
    case txidSnapshot
    
    /// universally unique identifier
    case uuid
    
    /// XML data
    case xml
    
    /// User-defined type
    case custom(String)
    
    /// See `SQLSerializable`.
    public func serialize(_ binds: inout [Encodable]) -> String {
        switch self {
        case .bigint: return "BIGINT"
        case .bigserial: return "BIGSERIAL"
        case .varbit(let n):
            if let n = n {
                return "VARBIT(" + n.description + ")"
            } else {
                return "VARBIT"
            }
        case .varchar(let n):
            if let n = n {
                return "VARCHAR(" + n.description + ")"
            } else {
                return "VARCHAR"
            }
        case .bit(let n):
            if let n = n {
                return "BIT(" + n.description + ")"
            } else {
                return "BIT"
            }
        case .boolean: return "BOOLEAN"
        case .box: return "BOX"
        case .bytea: return "BYTEA"
        case .char(let n):
            if let n = n {
                return "CHAR(" + n.description + ")"
            } else {
                return "CHAR"
            }
        case .cidr: return "CIDR"
        case .circle: return "CIRCLE"
        case .date: return "DATE"
        case .doublePrecision: return "DOUBLE PRECISION"
        case .inet: return "INET"
        case .integer: return "INTEGER"
        case .interval: return "INTEVERAL"
        case .json: return "JSON"
        case .jsonb: return "JSONB"
        case .line: return "LINE"
        case .lseg: return "LSEG"
        case .macaddr: return "MACADDR"
        case .macaddr8: return "MACADDER8"
        case .money: return "MONEY"
        case .numeric(let sp):
            if let sp = sp {
                return "NUMERIC(" + sp.0.description + ", " + sp.1.description + ")"
            } else {
                return "NUMERIC"
            }
        case .path: return "PATH"
        case .pgLSN: return "PG_LSN"
        case .point: return "POINT"
        case .polygon: return "POLYGON"
        case .real: return "REAL"
        case .smallint: return "SMALLINT"
        case .smallserial: return "SMALLSERIAL"
        case .serial: return "SERIAL"
        case .text: return "TEXT"
        case .time(let p):
            if let p = p {
                return "TIME(" + p.description + ")"
            } else {
                return "TIME"
            }
        case .timetz(let p):
            if let p = p {
                return "TIMETZ(" + p.description + ")"
            } else {
                return "TIMETZ"
            }
        case .timestamp(let p):
            if let p = p {
                return "TIMESTAMP(" + p.description + ")"
            } else {
                return "TIMESTAMP"
            }
        case .timestamptz(let p):
            if let p = p {
                return "TIMESTAMPTZ(" + p.description + ")"
            } else {
                return "TIMESTAMPTZ"
            }
        case .tsquery: return "TSQUERY"
        case .tsvector: return "TSVECTOR"
        case .txidSnapshot: return "TXID_SNAPSHOT"
        case .uuid: return "UUID"
        case .xml: return "XML"
        case .custom(let custom): return custom
        }
    }
}
