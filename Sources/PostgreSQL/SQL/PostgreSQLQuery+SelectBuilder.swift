extension PostgreSQLQuery {
    public final class SelectBuilder<D> where D: Decodable {
        public var connection: PostgreSQLConnection
        public var select: Select
        public init(decoding: D.Type, on connection: PostgreSQLConnection) {
            self.select = .init(tables: [])
            self.connection = connection
        }
        
        public func from(_ tables: TableName...) -> Self {
            select.tables += tables
            return self
        }
        
        public func keys(_ keys: Key...) -> Self {
            select.keys += keys
            return self
        }
        
        public func all() -> Future<[D]> {
            var results: [D] = []
            return run { results.append($0) }.map { results }
        }
        
        public func run(into handler: @escaping (D) throws -> ()) -> Future<Void> {
            return connection.query(.select(select)) { row in
                let result = try PostgreSQLRowDecoder().decode(D.self, from: row)
                try handler(result)
            }
        }
    }
}

extension PostgreSQLConnection {
    public func select<D>(_ type: D.Type) -> PostgreSQLQuery.SelectBuilder<D>
        where D: Decodable
    {
        return .init(decoding: D.self, on: self)
    }
}
