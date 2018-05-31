extension Query where Database == PostgreSQLDatabase {
    public struct ColumnType {
        /// `BOOL`.
        public static var bool:  ColumnType {
            return .init(name: "BOOL")
        }
        
        /// `CHAR(n)`
        ///
        /// - parameters:
        ///     - length: Maximum characters to allow.
        public static func char(_ length: Int) -> ColumnType {
            return .init(name: "CHAR", parameters: [length.description])
        }
        
        /// `VARCHAR(n)`
        ///
        /// - parameters:
        ///     - length: Maximum characters to allow.
        public static func varchar(_ length: Int) -> ColumnType {
            return .init(name: "VARCHAR", parameters: [length.description])
        }
        
        /// `TEXT`
        public static var text: ColumnType {
            return .init(name: "TEXT")
        }
        
        /// `SMALLINT`
        public static var smallint: ColumnType {
            return .init(name: "SMALLINT")
        }
        
        /// `INT`
        public static var int: ColumnType {
            return .init(name: "INT")
        }
        
        /// `BIGINT`
        public static var bigint: ColumnType {
            return .init(name: "BIGINT")
        }
        
        /// `SMALLSERIAL`
        public static var smallserial: ColumnType {
            return .init(name: "SMALL SERIAL")
        }
        
        /// `SERIAL`
        public static var serial: ColumnType {
            return .init(name: "SERIAL")
        }
        
        /// `BIGSERIAL`
        public static var bigserial: ColumnType {
            return .init(name: "BIGSERIAL")
        }
        
        /// `REAL`
        public static var real: ColumnType {
            return .init(name: "REAL")
        }
        
        /// `DOUBLE PRECISION`
        public static var double: ColumnType {
            return .init(name: "DOUBLE PRECISION")
        }
        
        /// `DATE`
        public static var date: ColumnType {
            return .init(name: "DATE")
        }
        
        /// `TIMESTAMP`
        public static var timestamp: ColumnType {
            return .init(name: "TIMESTAMP")
        }
        
        public enum Default {
            case computed(Query.DML.ComputedColumn)
            case unescaped(String)
        }
        
        public var name: String
        public var parameters: [String]
        public var primaryKey: Bool
        public var nullable: Bool
        public var generatedIdentity: Bool
        public var `default`: Default?
        
        public init(name: String, parameters: [String] = [], primaryKey: Bool = false, nullable: Bool = false, generatedIdentity: Bool = false, default: Default? = nil) {
            self.name = name
            self.parameters = parameters
            self.primaryKey = primaryKey
            self.nullable = nullable
            self.generatedIdentity = generatedIdentity
            self.default = `default`
        }
        
        public init(_ dataType: PostgreSQLDataType, parameters: [String] = [], primaryKey: Bool = false, nullable: Bool = false, generatedIdentity: Bool = false, default: Default? = nil) {
            self.name = dataType.knownSQLName ?? "VOID"
            self.parameters = parameters
            self.primaryKey = primaryKey
            self.nullable = nullable
            self.generatedIdentity = generatedIdentity
            self.default = `default`
        }
    }
}
