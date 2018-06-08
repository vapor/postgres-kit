extension PostgreSQLQuery {
    public final class InsertBuilder<Table> where Table: PostgreSQLTable {
        public var query: Insert
        public let connection: PostgreSQLConnection
        
        init(table: Table.Type, on connection: PostgreSQLConnection) {
            self.query = .init(table: .init(name: Table.postgreSQLTable))
            self.connection = connection
        }
        
        @discardableResult
        public func values(_ value: Table) throws -> Self {
            let values = try PostgreSQLQueryEncoder().encode(value)
            if query.columns.isEmpty {
                query.columns = .init(values.keys)
            }
            query.values.append(values.map { (col, value) in
                switch value {
                case .null: return .default
                default: return value
                }
            })
            return self
        }
        
        @discardableResult
        public func returning(_ keys: Key...) -> Self {
            query.returning += keys
            return self
        }
        
        public func run<D>(decoding: D.Type) -> Future<D>
            where D: Decodable
        {
            return connection.query(.insert(query)).map { rows in
                return try PostgreSQLRowDecoder().decode(D.self, from: rows[0])
            }
        }
        
        public func run<D>(decoding: [D].Type) -> Future<[D]>
            where D: Decodable
        {
            return connection.query(.insert(query)).map { rows in
                return try rows.map { try PostgreSQLRowDecoder().decode(D.self, from: $0) }
            }
        }
        
        public func run() -> Future<Void> {
            return connection.query(.insert(query)).transform(to: ())
        }
    }
}

extension PostgreSQLConnection {
    public func insert<Table>(into: Table.Type) -> PostgreSQLQuery.InsertBuilder<Table>
        where Table: PostgreSQLTable
    {
        return .init(table: Table.self, on: self)
    }
}
