public struct PostgreSQLColumnType {
    public var name: String
    public var parameters: [String]
    
    public init(_ name: String, _ parameters: String...) {
        self.name = name
        self.parameters = parameters
    }
    
    /// `BOOL`.
    public static var bool: PostgreSQLColumnType {
        return "BOOL"
    }
    
    /// `CHAR`
    public static var char: PostgreSQLColumnType {
        return "CHAR"
    }
    
    /// `VARCHAR(n)`
    public static func varchar(_ n: Int) -> PostgreSQLColumnType {
        return .init("VARCHAR", n.description)
    }
    
    /// `TEXT`
    public static var text: PostgreSQLColumnType {
        return "TEXT"
    }
    
    /// `SMALLINT`
    public static var smallint: PostgreSQLColumnType {
        return "SMALLINT"
    }
    
    /// `INT`
    public static var int: PostgreSQLColumnType {
        return "INT"
    }
    
    /// `BIGINT`
    public static var bigint: PostgreSQLColumnType {
        return "BIGINT"
    }
    
    /// `SMALLSERIAL`
    public static var smallserial: PostgreSQLColumnType {
        return "SMALL SERIAL"
    }
    
    /// `SERIAL`
    public static var serial: PostgreSQLColumnType {
        return "SERIAL"
    }
    
    /// `BIGSERIAL`
    public static var bigserial: PostgreSQLColumnType {
        return "BIGSERIAL"
    }
    
    /// `REAL`
    public static var real: PostgreSQLColumnType {
        return "REAL"
    }
    
    /// `DOUBLE PRECISION`
    public static var doublePrecision: PostgreSQLColumnType {
        return "DOUBLE PRECISION"
    }
    
    /// `DATE`
    public static var date: PostgreSQLColumnType {
        return "DATE"
    }
    
    /// `TIMESTAMP`
    public static var timestamp: PostgreSQLColumnType {
        return "TIMESTAMP"
    }
    
    /// `UUID`
    public static var uuid: PostgreSQLColumnType {
        return "UUID"
    }
    
    /// `POINT`
    public static var point: PostgreSQLColumnType {
        return "POINT"
    }
    
    /// `JSON`
    public static var json: PostgreSQLColumnType {
        return "JSON"
    }
    
    /// `JSONB`
    public static var jsonb: PostgreSQLColumnType {
        return "JSONB"
    }
    
    /// `BYTEA`
    public static var bytea: PostgreSQLColumnType {
        return "BYTEA"
    }
}

extension PostgreSQLColumnType: ExpressibleByStringLiteral {
    /// See `ExpressibleByStringLiteral`.
    public init(stringLiteral value: String) {
        self.init(value)
    }
}
