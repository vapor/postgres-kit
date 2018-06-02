extension PostgreSQLDatabase {
    public enum ColumnType {
        /// `BOOL`.
        public static var bool: String {
            return "BOOL"
        }
        
        /// `CHAR`
        public static var char: String {
            return "CHAR"
        }
        
        /// `VARCHAR`
        public static var varchar: String {
            return "VARCHAR"
        }
        
        /// `TEXT`
        public static var text: String {
            return "TEXT"
        }
        
        /// `SMALLINT`
        public static var smallint: String {
            return "SMALLINT"
        }
        
        /// `INT`
        public static var int: String {
            return "INT"
        }
        
        /// `BIGINT`
        public static var bigint: String {
            return "BIGINT"
        }
        
        /// `SMALLSERIAL`
        public static var smallserial: String {
            return "SMALL SERIAL"
        }
        
        /// `SERIAL`
        public static var serial: String {
            return "SERIAL"
        }
        
        /// `BIGSERIAL`
        public static var bigserial: String {
            return "BIGSERIAL"
        }
        
        /// `REAL`
        public static var real: String {
            return "REAL"
        }
        
        /// `DOUBLE PRECISION`
        public static var doublePrecision: String {
            return "DOUBLE PRECISION"
        }
        
        /// `DATE`
        public static var date: String {
            return "DATE"
        }
        
        /// `TIMESTAMP`
        public static var timestamp: String {
            return "TIMESTAMP"
        }
        
        /// `UUID`
        public static var uuid: String {
            return "UUID"
        }
        
        /// `POINT`
        public static var point: String {
            return "POINT"
        }
        
        /// `JSON`
        public static var json: String {
            return "JSON"
        }
        
        /// `JSONB`
        public static var jsonb: String {
            return "JSONB"
        }
        
        /// `BYTEA`
        public static var bytea: String {
            return "BYTEA"
        }
    }
}
