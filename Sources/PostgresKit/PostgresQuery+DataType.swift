import SQLKit

extension PostgresQuery {
    /// PostgreSQL specific `SQLDataType`.
    public struct DataType: SQLDataType, Equatable {
        public static var blob: PostgresQuery.DataType {
            return .varbit
        }
        
        /// See `Equatable`.
        public static func == (lhs: DataType, rhs: DataType) -> Bool {
            // FIXME: more performant equatable is possible
            var binds: [Encodable] = []
            return lhs.serialize(&binds) == rhs.serialize(&binds)
        }
        
        /// signed eight-byte integer
        public static var int8: DataType {
            return .bigint
        }
        
        /// signed eight-byte integer
        public static var bigint: DataType {
            return .init(.bigint)
        }
        
        /// autoincrementing eight-byte integer
        public static var serial8: DataType {
            return .bigserial
        }
        
        /// autoincrementing eight-byte integer
        public static var bigserial: DataType {
            return .init(.bigserial)
        }
        
        /// fixed-length bit string
        public static var bit: DataType {
            return .init(.bit(nil))
        }
        
        /// fixed-length bit string
        public static func bit(_ n: Int) -> DataType {
            return .init(.bit(n))
        }
        
        /// variable-length bit string
        public static var varbit: DataType {
            return .init(.varbit(nil))
        }
        
        /// variable-length bit string
        public static func varbit(_ n: Int) -> DataType {
            return .init(.varbit(n))
        }
        
        /// logical Boolean (true/false)
        public static var bool: DataType {
            return .boolean
        }
        
        /// logical Boolean (true/false)
        public static var boolean: DataType {
            return .init(.boolean)
        }
        
        /// rectangular box on a plane
        public static var box: DataType {
            return .init(.box)
        }
        
        /// binary data (“byte array”)
        public static var bytea: DataType {
            return .init(.bytea)
        }
        
        /// fixed-length character string
        public static var char: DataType {
            return .init(.char(nil))
        }
        
        /// fixed-length character string
        public static func char(_ n: Int) -> DataType {
            return .init(.char(n))
        }
        
        /// variable-length character string
        public static var varchar: DataType {
            return .init(.varchar(nil))
        }
        
        /// variable-length character string
        public static func varchar(_ n: Int) -> DataType {
            return .init(.varchar(n))
        }
        
        /// IPv4 or IPv6 network address
        public static var cidr: DataType {
            return .init(.cidr)
        }
        
        /// circle on a plane
        public static var circle: DataType {
            return .init(.circle)
        }
        
        /// calendar date (year, month, day)
        public static var date: DataType {
            return .init(.date)
        }
        
        /// floating-point number (8 bytes)
        public static var float8: DataType {
            return .doublePrecision
        }
        
        /// floating-point number (8 bytes)
        public static var doublePrecision: DataType {
            return .init(.doublePrecision)
        }
        
        /// IPv4 or IPv6 host address
        public static var inet: DataType {
            return .init(.inet)
        }
        
        /// signed four-byte integer
        public static var int: DataType {
            return .integer
        }
        
        /// signed four-byte integer
        public static var int4: DataType {
            return .integer
        }
        
        /// signed four-byte integer
        public static var integer: DataType {
            return .init(.integer)
        }
        
        /// time span
        public static var interval: DataType {
            return .init(.interval)
        }
        
        /// textual JSON data
        public static var json: DataType {
            return .init(.json)
        }
        
        /// binary JSON data, decomposed
        public static var jsonb: DataType {
            return .init(.jsonb)
        }
        
        /// infinite line on a plane
        public static var line: DataType {
            return .init(.line)
        }
        
        /// line segment on a plane
        public static var lseg: DataType {
            return .init(.lseg)
        }
        
        /// MAC (Media Access Control) address
        public static var macaddr: DataType {
            return .init(.macaddr)
        }
        
        /// MAC (Media Access Control) address (EUI-64 format)
        public static var macaddr8: DataType {
            return .init(.macaddr8)
        }
        
        /// currency amount
        public static var money: DataType {
            return .init(.money)
        }
        
        /// exact numeric of selectable precision
        public static var decimal: DataType {
            return .init(.numeric(nil))
        }
        
        /// exact numeric of selectable precision
        public static func decimal(_ p: Int, _ s: Int) -> DataType {
            return .init(.numeric((p, s)))
        }
        
        /// exact numeric of selectable precision
        public static func numeric(_ p: Int, _ s: Int) -> DataType {
            return .init(.numeric((p, s)))
        }
        
        /// exact numeric of selectable precision
        public static var numeric: DataType {
            return .init(.numeric(nil))
        }
        
        /// geometric path on a plane
        public static var path: DataType {
            return .init(.path)
        }
        
        /// PostgreSQL Log Sequence Number
        public static var pgLSN: DataType {
            return .init(.pgLSN)
        }
        
        /// geometric point on a plane
        public static var point: DataType {
            return .init(.point)
        }
        
        /// closed geometric path on a plane
        public static var polygon: DataType {
            return .init(.polygon)
        }
        
        /// single precision floating-point number (4 bytes)
        public static var float4: DataType {
            return .real
        }
        
        /// single precision floating-point number (4 bytes)
        public static var real: DataType {
            return .init(.real)
        }
        
        /// signed two-byte integer
        public static var int2: DataType {
            return .smallint
        }
        
        /// signed two-byte integer
        public static var smallint: DataType {
            return .init(.smallint)        }
        
        /// autoincrementing two-byte integer
        public static var serial2: DataType {
            return .smallserial
        }
        
        /// autoincrementing two-byte integer
        public static var smallserial: DataType {
            return .init(.smallserial)
        }
        
        /// autoincrementing four-byte integer
        public static var serial4: DataType {
            return .serial
        }
        
        /// autoincrementing four-byte integer
        public static var serial: DataType {
            return .init(.serial)
        }
        
        /// variable-length character string
        public static var text: DataType {
            return .init(.text)
        }
        
        /// time of day (no time zone)
        public static var time: DataType {
            return .init(.time(nil))
        }
        
        /// time of day (no time zone)
        public static func time(_ n: Int) -> DataType {
            return .init(.time(n))
        }
        
        /// time of day, including time zone
        public static var timetz: DataType {
            return .init(.timetz(nil))
        }
        
        /// time of day, including time zone
        public static func timetz(_ n: Int) -> DataType {
            return .init(.timetz(n))
        }
        
        /// date and time (no time zone)
        public static var timestamp: DataType {
            return .init(.timestamp(nil))
        }
        
        /// date and time (no time zone)
        public static func timestamp(_ n: Int) -> DataType {
            return .init(.timestamp(n))
        }
        
        /// date and time, including time zone
        public static var timestamptz: DataType {
            return .init(.timestamptz(nil))
        }
        
        /// date and time, including time zone
        public static func timestamptz(_ n: Int) -> DataType {
            return .init(.timestamptz(n))
        }
        
        /// text search query
        public static var tsquery: DataType {
            return .init(.tsquery)
        }
        
        /// text search document
        public static var tsvector: DataType {
            return .init(.tsvector)
        }
        
        /// user-level transaction ID snapshot
        public static var txidSnapshot: DataType {
            return .init(.txidSnapshot)
        }
        
        /// universally unique identifier
        public static var uuid: DataType {
            return .init(.uuid)
        }
        
        /// XML data
        public static var xml: DataType {
            return .init(.xml)
        }
        
        /// User-defined type
        public static func custom(_ name: String) -> DataType {
            return .init(.custom(name))
        }
        
        /// Creates an array type from a `PostgreSQLDataType`.
        public static func array(_ dataType: DataType) -> DataType {
            return .init(dataType.primitive, isArray: true)
        }
        
        let primitive: Primitive
        let isArray: Bool
        
        private init(_ primitive: Primitive, isArray: Bool = false) {
            self.primitive = primitive
            self.isArray = isArray
        }
        
        enum Primitive {
            /// signed eight-byte integer
            case bigint
            
            /// autoincrementing eight-byte integer
            case bigserial
            
            /// fixed-length bit string
            case bit(Int?)
            
            /// variable-length bit string
            case varbit(Int?)
            
            /// logical Boolean (true/false)
            case boolean
            
            /// rectangular box on a plane
            case box
            
            /// binary data (“byte array”)
            case bytea
            
            /// fixed-length character string
            case char(Int?)
            
            /// variable-length character string
            case varchar(Int?)
            
            /// IPv4 or IPv6 network address
            case cidr
            
            /// circle on a plane
            case circle
            
            /// calendar date (year, month, day)
            case date
            
            /// floating-point number (8 bytes)
            case doublePrecision
            
            /// IPv4 or IPv6 host address
            case inet
            
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
            case real
            
            /// signed two-byte integer
            case smallint
            
            /// autoincrementing two-byte integer
            case smallserial
            
            /// autoincrementing four-byte integer
            case serial
            
            /// variable-length character string
            case text
            
            /// time of day (no time zone)
            case time(Int?)
            
            /// time of day, including time zone
            case timetz(Int?)
            
            /// date and time (no time zone)
            case timestamp(Int?)
            
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
        
        /// See `SQLSerializable`.
        public func serialize(_ binds: inout [Encodable]) -> String {
            if isArray {
                return primitive.serialize(&binds) + "[]"
            } else {
                return primitive.serialize(&binds)
            }
        }
    }
}
