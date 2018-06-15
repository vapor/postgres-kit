extension PostgreSQLQuery {
    public final class SelectBuilder {
        public var connection: PostgreSQLConnection
        public var query: Select
        init(on connection: PostgreSQLConnection) {
            self.query = .init(tables: [])
            self.connection = connection
        }
    
        @discardableResult
        public func all() -> Self {
            return keys(.all)
        }
        
        public func from<Table>(_ table: Table.Type) -> Self
            where Table: PostgreSQLTable
        {
            query.tables.append(.init(name: Table.postgreSQLTable))
            return self
        }
        
        public func from(_ tables: TableName...) -> Self {
            query.tables += tables
            return self
        }
        
        public func keys(_ keys: Key...) -> Self {
            query.keys += keys
            return self
        }
        
        @discardableResult
        public func order<T, V>(by keyPath: KeyPath<T, V>, _ direction: PostgreSQLQuery.OrderBy.Direction = .ascending) -> Self
            where T: PostgreSQLTable
        {
            query.orderBy.append(.init(.column(keyPath.column), direction: direction))
            return self
        }
        
        public func run<D>(decoding type: D.Type) -> Future<[D]>
            where D: Decodable
        {
            var results: [D] = []
            return run(decoding: D.self) { results.append($0) }.map { results }
        }
        
        public func run<D>(decoding type: D.Type, into handler: @escaping (D) throws -> ()) -> Future<Void>
            where D: Decodable
        {
            return connection.query(.select(query)) { row in
                let result = try PostgreSQLRowDecoder().decode(D.self, from: row)
                try handler(result)
            }
        }
    }
}

extension PostgreSQLConnection {
    public func select() -> PostgreSQLQuery.SelectBuilder {
        return .init(on: self)
    }
}
