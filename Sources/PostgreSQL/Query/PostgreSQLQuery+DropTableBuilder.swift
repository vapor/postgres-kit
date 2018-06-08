extension PostgreSQLQuery {
    public final class DropTableBuilder<Table> where Table: PostgreSQLTable {
        public var query: DropTable
        public let connection: PostgreSQLConnection
        
        init(table: Table.Type, on connection: PostgreSQLConnection) {
            self.query = .init(name: Table.postgreSQLTable)
            self.connection = connection
        }
        
        @discardableResult
        public func ifExists() -> Self {
            query.ifExists = true
            return self
        }
        
        public func run() -> Future<Void> {
            return connection.query(.dropTable(query)).transform(to: ())
        }
    }
}

extension PostgreSQLConnection {
    public func drop<Table>(table: Table.Type) -> PostgreSQLQuery.DropTableBuilder<Table>
        where Table: PostgreSQLTable
    {
        return .init(table: Table.self, on: self)
    }
}
