extension PostgreSQLQuery {
    public enum Value {
        public static func bind(_ encodable: Encodable) throws -> Value {
            return try PostgreSQLValueEncoder().encode(encodable)
        }
        
        public static func binds(_ encodables: [Encodable]) throws -> Value {
            return try .values(encodables.map { try .bind($0) })
        }
        
        case values([Value])
        case data(PostgreSQLData)
        case `default`
        case expression(Expression)
        case null
    }
}

extension PostgreSQLSerializer {
    internal mutating func serialize(_ value: PostgreSQLQuery.Value, _ binds: inout [PostgreSQLData]) -> String {
        switch value {
        case .values(let values): return group(values.map { self.serialize($0, &binds) })
        case .data(let data):
            binds.append(data)
            return nextPlaceholder()
        case .`default`: return "DEFAULT"
        case .expression(let expression): return serialize(expression)
        case .null: return "NULL"
        }
    }
}
