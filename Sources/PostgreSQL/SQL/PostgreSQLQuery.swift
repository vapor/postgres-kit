public protocol PostgreSQLValueRepresentable {
    var postgreSQLValue: PostgreSQLQuery.DML.Value { get }
}

public enum PostgreSQLQuery {
    // MARK: DDL
    
    public static func drop(table: String, ifExists: Bool = false) -> PostgreSQLQuery {
        let drop = DDL.Drop(name: table, ifExists: ifExists)
        return .ddl(.drop(drop))
    }
    
    public static func create(storage: DDL.Create.Storage = .permanent, table: String, ifNotExists: Bool = false, _ items: DDL.Item...) -> PostgreSQLQuery {
        let query = DDL.Create(
            storage: storage,
            ifNotExists: ifNotExists,
            name: table,
            items: items
        )
        return .ddl(.create(query))
    }

    public enum DDL {
        public struct ColumnDefinition {
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
            }
            
            public struct Constraint {
                public static var notNull: Constraint {
                    return .init(.notNull)
                }
                
                public static var primaryKey: Constraint {
                    return .init(.primaryKey)
                }
                
                public static func generated(_ type: ConstraintType.Generated) -> Constraint {
                    return .init(.generated(type))
                }
                
                public enum ConstraintType {
                    case notNull
                    case null
                    case check(Expression, noInherit: Bool)
                    case `default`(Expression)
                    public enum Generated {
                        case always
                        case byDefault
                    }
                    #warning("sequence options")
                    case generated(Generated)
                    case unique
                    case primaryKey
                    case references(reftable: String, refcolumn: String, onDelete: ForeignKeyAction?, onUpdate: ForeignKeyAction?)
                }
                
                public var name: String?
                public var type: ConstraintType
                public init(_ type: ConstraintType, as name: String? = nil) {
                    self.type = type
                    self.name = name
                }
            }
            
            public var name: String
            public var dataType: DataType
            public var collate: String?
            public var constraints: [Constraint]
            
            public init(name: String, dataType: DataType, collate: String? = nil, constraints: [Constraint] = []) {
                self.name = name
                self.dataType = dataType
                self.collate = collate
                self.constraints = constraints
            }
        }
        
        public struct Constraint {
            public enum ConstraintType {
                case check(Expression, noInherit: Bool)
                case unique(columns: [String], IndexParameters)
                case primaryKey(column: String, IndexParameters)
                #warning("exclude")
                case foreignKey(columns: [String], reftable: String, refcolumns: [String], onDelete: ForeignKeyAction?, onUpdate: ForeignKeyAction?)
            }
            
            public var name: String?
            public var type: ConstraintType
            public init(_ type: ConstraintType, as name: String? = nil) {
                self.type = type
                self.name = name
            }
        }
        
        public struct Create {
            public enum Storage {
                case permanent
                case temporary
                case unlogged
            }
            public var storage: Storage
            public var ifNotExists: Bool
            public var name: String
            public var items: [Item]
            
            public init(storage: Storage = .permanent, ifNotExists: Bool = false, name: String, items: [Item]) {
                self.storage = storage
                self.ifNotExists = ifNotExists
                self.name = name
                self.items = items
            }
        }
        
        public struct Drop {
            public var name: String
            public var ifExists: Bool
            public init(name: String, ifExists: Bool = false) {
                self.name = name
                self.ifExists = ifExists
            }
        }
        
        public enum ForeignKeyAction {
            case nullify
        }
        
        public enum Item {
            public static func column(_ name: String, _ dataType: ColumnDefinition.DataType, collate: String? = nil, _ constraints: ColumnDefinition.Constraint...) -> Item {
                let column = ColumnDefinition(name: name, dataType: dataType, collate: collate, constraints: constraints)
                return .columnDefinition(column)
            }
            
            case columnDefinition(ColumnDefinition)
            case tableConstraint(Constraint)
            #warning("FIXME: like")
        }
        
        public struct IndexParameters {
            
        }
        
        case create(Create)
        case drop(Drop)
    }
    
    // MARK: DML
    
    public static func insert(into table: DML.Table, values: [String: DML.Value], returning keys: DML.Key...) -> PostgreSQLQuery {
        let insert = DML.Insert(table: table, values: values, returning: keys)
        return .dml(.insert(insert))
    }
    
    public static func select(distinct: [Column], _ keys: [DML.Key] = [], from: [DML.Table] = []) -> PostgreSQLQuery {
        let query = DML.Select(
            candidates: .distinct(columns: distinct),
            keys: keys,
            from: from
        )
        return .dml(.select(query))
    }
    
    public static func select(_ keys: DML.Key..., from: [DML.Table] = []) -> PostgreSQLQuery {
        let query = DML.Select(
            candidates: .all,
            keys: keys,
            from: from
        )
        return .dml(.select(query))
    }
    
    public static func select(_ keys: [DML.Key] = [], from: [DML.Table] = []) -> PostgreSQLQuery {
        let query = DML.Select(
            candidates: .all,
            keys: keys,
            from: from
        )
        return .dml(.select(query))
    }
    
    public enum DML {
        public struct Table {
            public var name: String
            public var alias: String?
            
            public init(name: String, as alias: String? = nil) {
                self.name = name
                self.alias = alias
            }
        }
        
        public enum Key {
            public static var version: Key {
                return .expression(.function("version"))
            }
            
            public static func function(_ name: String, _ parameters: Expression..., as alias: String? = nil) -> Key {
                return .expression(.function(name, parameters), as: alias)
            }
            
            public static func expression(_ expression: Expression, as alias: String? = nil) -> Key {
                return .expression(expression, alias: alias)
            }
            
            case all
            case expression(Expression, alias: String?)
        }
        
        public struct Insert {
            public var table: Table
            public var values: [String: DML.Value]
            public var returning: [Key]
            
            public init(table: Table, values: [String: DML.Value], returning: [Key] = []) {
                self.table = table
                self.values = values
                self.returning = returning
            }
        }
        
        public struct Select {
            public enum Candidates {
                /// All row candiates are available for selection.
                case all
                /// Only distinct row candidates are available for selection.
                case distinct(columns: [Column])
            }
            
            public var candidates: Candidates
            public var keys: [Key]
            public var from: [Table]
        }
        
        public enum Value {
            public static func bind(_ encodable: Encodable) throws -> Value {
                return try PostgreSQLValueEncoder().encode(encodable)
            }
            
            case values([Value])
            case data(PostgreSQLData)
            case `default`
            case expression(Expression)
            case null
        }
        
        case insert(Insert)
        case select(Select)
    }
    
    public struct Column: Hashable {
        var table: String?
        var name: String
        
        public init(table: String? = nil, name: String) {
            self.table = table
            self.name = name
        }
    }
    
    public enum Expression {
        public static func function(_ name: String, _ parameters: Expression...) -> Expression {
            return .function(name, parameters)
        }
        
        public static func function(_ name: String, _ parameters: [Expression]) -> Expression {
            return .function(.init(name: name, parameters: parameters))
        }
        
        public struct Function {
            var name: String
            var parameters: [Expression]
        }
        
        case column(Column)
        case function(Function)
        case stringLiteral(String)
        case literal(String)
    }
    
    // MARK: General
    
    public static func raw(_ query: String, _ binds: [PostgreSQLDataConvertible]) throws -> PostgreSQLQuery {
        return try .raw(query: query, binds: binds.map { try $0.convertToPostgreSQLData() })
    }
    
    public static func raw(_ query: String, _ binds: [PostgreSQLData] = []) -> PostgreSQLQuery {
        return .raw(query: query, binds: binds)
    }

    // MARK: Cases
    
    case ddl(DDL)
    case dml(DML)
    
    case raw(query: String, binds: [PostgreSQLData])
    
    case unlisten(channel: String)
    case listen(channel: String)
    case notify(channel: String, message: String)
}

extension Array: ExpressibleByStringLiteral, ExpressibleByUnicodeScalarLiteral, ExpressibleByExtendedGraphemeClusterLiteral
    where Element == PostgreSQLQuery.DML.Table
{
    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String
    
    public init(stringLiteral value: String) {
        self = [.init(name: value)]
    }
}

extension PostgreSQLQuery.Expression: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .stringLiteral(value)
    }
}

extension PostgreSQLQuery.Expression: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .literal(value.description)
    }
}

extension PostgreSQLQuery.Expression: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .literal(value.description)
    }
}

extension PostgreSQLQuery.DML.Key: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .expression(.column(.init(stringLiteral: value)), alias: nil)
    }
}

extension PostgreSQLQuery.DML.Table: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(name: value)
    }
}

extension PostgreSQLQuery.Column: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(name: value)
    }
}

extension PostgreSQLQuery: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .raw(value, [])
    }
}

extension PostgreSQLQuery {
    public func serialize(binds: inout [PostgreSQLData]) -> String {
        var serializer = Serializer()
        return serializer.serialize(self, binds: &binds)
    }
    
    private struct Serializer {
        var placeholderOffset: Int
        init() {
            self.placeholderOffset = 1
        }
        
        mutating func serialize(_ query: PostgreSQLQuery, binds: inout [PostgreSQLData]) -> String {
            switch query {
            case .ddl(let ddl): return serialize(ddl)
            case .dml(let dml): return serialize(dml, binds: &binds)
            case .listen(let channel): return "LISTEN " + escapeString(channel)
            case .notify(let channel, let message): return "NOTIFY " + escapeString(channel) + ", " + stringLiteral(message)
            case .raw(let raw, let values):
                binds = values
                return raw
            case .unlisten(let channel): return "UNLISTEN " + escapeString(channel)
            }
        }
        
        // MARK: DDL
        
        private func serialize(_ table: DDL) -> String {
            switch table {
            case .create(let create): return serialize(create)
            case .drop(let drop): return serialize(drop)
            }
        }
        
        private func serialize(_ drop: DDL.Drop) -> String {
            var sql: [String] = []
            sql.append("DROP TABLE")
            if drop.ifExists {
                sql.append("IF EXISTS")
            }
            sql.append(escapeString(drop.name))
            return sql.joined(separator: " ")
        }
        
        private func serialize(_ create: DDL.Create) -> String {
            var sql: [String] = []
            sql.append("CREATE")
            switch create.storage {
            case .permanent: break
            case .temporary: sql.append("TEMP")
            case .unlogged: sql.append("UNLOGGED")
            }
            sql.append("TABLE")
            if create.ifNotExists {
                sql.append("IF NOT EXISTS")
            }
            sql.append(escapeString(create.name))
            sql.append(group(create.items.map(serialize)))
            return sql.joined(separator: " ")
        }
        
        private func serialize(_ tableItem: DDL.Item) -> String {
            switch tableItem {
            case .columnDefinition(let column): return serialize(column)
            case .tableConstraint(let constraint): return serialize(constraint)
            }
        }
        
        private func serialize(_ column: DDL.Constraint) -> String {
            fatalError()
        }
        
        private func serialize(_ column: DDL.ColumnDefinition) -> String {
            var sql: [String] = []
            sql.append(escapeString(column.name))
            sql.append(serialize(column.dataType))
            if let collate = column.collate {
                sql.append("COLLATE")
                sql.append(collate)
            }
            sql += column.constraints.map(serialize)
            return sql.joined(separator: " ")
        }
        
        private func serialize(_ dataType: DDL.ColumnDefinition.DataType) -> String {
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
            }
        }
        
        private func serialize(_ constraint: DDL.ColumnDefinition.Constraint) -> String {
            if let name = constraint.name {
                return "CONSTRAINT " + name + " " + serialize(constraint.type)
            } else {
                return serialize(constraint.type)
            }
        }
        
        private func serialize(_ constraintType: DDL.ColumnDefinition.Constraint.ConstraintType) -> String {
            switch constraintType {
            case .null: return "NULL"
            case .notNull: return "NOT NULL"
            case .check(let expr, let noInherit):
                if noInherit {
                    return serialize(expr) + " NO INHERIT"
                } else {
                    return serialize(expr)
                }
            case .default(let expr): return "DEFAULT " + serialize(expr)
            case .generated(let generated):
                switch generated {
                case .always: return "GENERATED ALWAYS AS IDENTITY"
                case .byDefault: return "GENERATED BY DEFAULT AS IDENTITY"
                }
            case .unique: return "UNIQUE"
            case .primaryKey: return "PRIMARY KEY"
            case .references(let reftable, let refcolumn, let onDelete, let onUpdate):
                // REFERENCES reftable [ ( refcolumn ) ] [ MATCH FULL | MATCH PARTIAL | MATCH SIMPLE ]
                //   [ ON DELETE action ] [ ON UPDATE action ] }
                var sql: [String] = []
                sql.append("REFERENCES")
                sql.append(reftable)
                sql.append("(" + refcolumn + ")")
                if let onDelete = onDelete {
                    sql.append("ON DELETE")
                    sql.append(serialize(onDelete))
                }
                if let onUpdate = onUpdate {
                    sql.append("ON UPDATE")
                    sql.append(serialize(onUpdate))
                }
                return sql.joined(separator: " ")
            }
        }
        
        private func serialize(_ action: DDL.ForeignKeyAction) -> String {
            switch action {
            case .nullify: return "NULLIFY"
            }
        }
        
        // MARK: DML
        
        private mutating func serialize(_ table: DML, binds: inout [PostgreSQLData]) -> String {
            switch table {
            case .insert(let insert): return serialize(insert, binds: &binds)
            case .select(let select): return serialize(select, binds: &binds)
            }
        }
        
        private mutating func serialize(_ insert: DML.Insert, binds: inout [PostgreSQLData]) -> String {
            var sql: [String] = []
            sql.append("INSERT INTO")
            sql.append(serialize(insert.table))
            if !insert.values.isEmpty {
                sql.append(group(insert.values.keys.map(escapeString)))
                sql.append("VALUES")
                sql.append(group(insert.values.values.map { serialize($0, binds: &binds) }))
            } else {
                sql.append("DEFAULT VALUES")
            }
            if !insert.returning.isEmpty {
                sql.append("RETURNING")
                sql.append(insert.returning.map(serialize).joined(separator: ", "))
            }
            return sql.joined(separator: " ")
        }
        
        private mutating func serialize(_ value: DML.Value, binds: inout [PostgreSQLData]) -> String {
            switch value {
            case .values(let values): return group(values.map { self.serialize($0, binds: &binds) })
            case .data(let data):
                binds.append(data)
                return nextPlaceholder()
            case .`default`: return "DEFAULT"
            case .expression(let expression): return serialize(expression)
            case .null: return "NULL"
            }
        }
        
        private func serialize(_ select: DML.Select, binds: inout [PostgreSQLData]) -> String {
            var sql: [String] = []
            sql.append("SELECT")
            switch select.candidates {
            case .all: break
            case .distinct(let columns):
                sql.append("DISTINCT")
                if !columns.isEmpty {
                    sql.append("(" + columns.map(serialize).joined(separator: ",") + ")")
                }
            }
            sql.append(select.keys.map(serialize).joined(separator: ", "))
            if !select.from.isEmpty {
                sql.append("FROM")
                sql.append(select.from.map(serialize).joined(separator: ", "))
            }
            return sql.joined(separator: " ")
        }
        
        private func serialize(_ key: DML.Key) -> String {
            switch key {
            case .all: return "*"
            case .expression(let expression, let alias):
                if let alias = alias {
                    return serialize(expression) + " AS " + escapeString(alias)
                } else {
                    return serialize(expression)
                }
            }
        }
        
        private func serialize(_ table: DML.Table) -> String {
            if let alias = table.alias {
                return escapeString(table.name) + " AS " + escapeString(alias)
            } else {
                return escapeString(table.name)
            }
        }
        
        // MARK: Generic
        
        private func serialize(_ column: Column) -> String {
            if let table = column.table {
                return escapeString(table) + "." + escapeString(column.name)
            } else {
                return escapeString(column.name)
            }
        }
        
        private func serialize(_ expression: Expression) -> String {
            switch expression {
            case .stringLiteral(let string): return stringLiteral(string)
            case .literal(let literal): return literal
            case .column(let column): return serialize(column)
            case .function(let function): return serialize(function)
            }
        }
        
        private func serialize(_ function: Expression.Function) -> String {
            return function.name + group(function.parameters.map(serialize))
        }
        
        private func group(_ strings: [String]) -> String {
            return "(" + strings.joined(separator: ", ") + ")"
        }
        
        private func escapeString(_ string: String) -> String {
            return "\"" + string + "\""
        }
        
        private func stringLiteral(_ string: String) -> String {
            return "'" + string + "'"
        }
        
        private mutating func nextPlaceholder() -> String {
            defer { placeholderOffset += 1 }
            return "$" + placeholderOffset.description
        }
    }
}
