extension PostgreSQLQuery {
    public static func raw(_ query: String, _ binds: [PostgreSQLDataConvertible]) throws -> PostgreSQLQuery {
        return try .raw(query: query, binds: binds.map { try $0.convertToPostgreSQLData() })
    }
    
    public static func raw(_ query: String, _ binds: [PostgreSQLData] = []) -> PostgreSQLQuery {
        return .raw(query: query, binds: binds)
    }
}

extension PostgreSQLQuery: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .raw(value, [])
    }
}
