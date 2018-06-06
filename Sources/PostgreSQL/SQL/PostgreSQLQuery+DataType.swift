extension PostgreSQLQuery {
    public enum DataType {
        /// int8    signed eight-byte integer
        case bigint
        /// serial8    autoincrementing eight-byte integer
        case bigserial
        /// fixed-length bit string
        public static var bit: DataType {
            return .bit(nil)
        }
        /// fixed-length bit string
        case bit(Int?)
        public static var varbit: DataType {
            return .varbit(nil)
        }
        /// variable-length bit string
        case varbit(Int?)
        /// logical Boolean (true/false)
        public static var bool: DataType {
            return .boolean
        }
        /// bool    logical Boolean (true/false)
        case boolean
        /// rectangular box on a plane
        case box
        /// binary data (“byte array”)
        case bytea
        /// fixed-length character string
        public static var char: DataType {
            return .char(nil)
        }
        /// [ (n) ]    char [ (n) ]    fixed-length character string
        case char(Int?)
        /// varying [ (n) ]    varchar [ (n) ]    variable-length character string
        public static var varchar: DataType {
            return .varchar(nil)
        }
        /// varying [ (n) ]    varchar [ (n) ]    variable-length character string
        case varchar(Int?)
        /// IPv4 or IPv6 network address
        case cidr
        /// circle on a plane
        case circle
        /// calendar date (year, month, day)
        case date
        /// precision    float8    double precision floating-point number (8 bytes)
        public static var float8: DataType {
            return .doublePrecision
        }
        /// precision    float8    double precision floating-point number (8 bytes)
        case doublePrecision
        /// IPv4 or IPv6 host address
        case inet
        /// int, int4    signed four-byte integer
        public static var int: DataType {
            return .integer
        }
        /// int, int4    signed four-byte integer
        public static var int4: DataType {
            return .integer
        }
        /// int, int4    signed four-byte integer
        case integer
        /// [ fields ] [ (p) ]         time span
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
        public static var decimal: DataType {
            return .numeric(nil)
        }
        /// exact numeric of selectable precision
        public static func decimal(_ p: Int, _ s: Int) -> DataType {
            return .numeric((p, s))
        }
        /// exact numeric of selectable precision
        public static func numeric(_ p: Int, _ s: Int) -> DataType {
            return .numeric((p, s))
        }
        /// exact numeric of selectable precision
        public static var numeric: DataType {
            return .numeric(nil)
        }
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
        public static var float4: DataType {
            return .real
        }
        /// single precision floating-point number (4 bytes)
        case real
        /// signed two-byte integer
        public static var int2: DataType {
            return .smallint
        }
        /// signed two-byte integer
        case smallint
        /// autoincrementing two-byte integer
        public static var serial2: DataType {
            return .smallint
        }
        /// autoincrementing two-byte integer
        case smallserial
        /// autoincrementing four-byte integer
        public static var serial4: DataType {
            return .smallint
        }
        /// autoincrementing four-byte integer
        case serial
        /// variable-length character string
        case text
        /// time of day (no time zone)
        public static var time: DataType {
            return .time(nil)
        }
        /// time of day (no time zone)
        case time(Int?)
        /// time of day, including time zone
        public static var timetz: DataType {
            return .timetz(nil)
        }
        /// time of day, including time zone
        case timetz(Int?)
        /// date and time (no time zone)
        public static var timestamp: DataType {
            return .timestamp(nil)
        }
        /// date and time (no time zone)
        case timestamp(Int?)
        /// date and time, including time zone
        public static var timestamptz: DataType {
            return .timestamptz(nil)
        }
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
    }
}

extension PostgreSQLSerializer {
    internal func serialize(_ dataType: PostgreSQLQuery.DataType) -> String {
        switch dataType {
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
