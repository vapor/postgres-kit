extension PostgresConnection: SQLDatabase { }

extension SQLDatabase where Self: PostgresClient {
    public func execute(sql query: SQLExpression, _ onRow: @escaping (SQLRow) throws -> ()) -> EventLoopFuture<Void> {
        var serializer = SQLSerializer(dialect: PostgresDialect())
        query.serialize(to: &serializer)
        do {
            return try self.query(serializer.sql, serializer.binds.map { encodable in
                return try PostgresDataEncoder().encode(encodable)
            }) { row in
                try onRow(row)
            }
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }
}

extension ConnectionPool: SQLDatabase where Source.Connection: SQLDatabase {
    public func execute(sql query: SQLExpression, _ onRow: @escaping (SQLRow) throws -> ()) -> EventLoopFuture<Void> {
        return self.withConnection { $0.execute(sql: query, onRow) }
    }
}

extension ConnectionPool: PostgresClient where Source.Connection: PostgresClient {
    public var eventLoop: EventLoop {
        return self.eventLoopGroup.next()
    }

    public func send(_ request: PostgresRequest) -> EventLoopFuture<Void> {
        return self.withConnection { $0.send(request) }
    }
}
