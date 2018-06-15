extension PostgreSQLQuery {
    public final class CreateTableBuilder<Table> where Table: PostgreSQLTable {
        public var query: CreateTable
        public let connection: PostgreSQLConnection
        
        init(table: String, on connection: PostgreSQLConnection) {
            self.query = .init(name: table, columns: [])
            self.connection = connection
        }
        
        @discardableResult
        public func column<V>(for keyPath: KeyPath<Table, V>, _ dataType: DataType, _ constraints: ColumnConstraint...) -> Self {
            query.columns.append(.init(
                name: keyPath.column.name,
                dataType: dataType,
                isArray: false,
                collate: nil,
                constraints: constraints
            ))
            return self
        }
        
        public func run() -> Future<Void> {
            return connection.query(.createTable(query)).transform(to: ())
        }
    }
}

extension PostgreSQLConnection {
    public func create<Table>(table: Table.Type) -> PostgreSQLQuery.CreateTableBuilder<Table>
        where Table: PostgreSQLTable
    {
        return .init(table: Table.postgreSQLTable, on: self)
    }
}
