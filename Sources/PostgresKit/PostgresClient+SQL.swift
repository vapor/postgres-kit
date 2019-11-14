import SQLKit

extension PostgresDatabase {
    public func sql() -> SQLDatabase {
        _PostgresSQLDatabase(database: self)
    }
}

private struct _PostgresSQLDatabase {
    let database: PostgresDatabase
}

extension _PostgresSQLDatabase: SQLDatabase {
    var logger: Logger {
        self.database.logger
    }
    
    var eventLoop: EventLoop {
        self.database.eventLoop
    }
    
    func execute(sql query: SQLExpression, _ onRow: @escaping (SQLRow) -> ()) -> EventLoopFuture<Void> {
        var serializer = SQLSerializer(dialect: PostgresDialect())
        query.serialize(to: &serializer)
        do {
            return try self.database.query(serializer.sql, serializer.binds.map { encodable in
                return try PostgresDataEncoder().encode(encodable)
            }) { row in
                onRow(row)
            }
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }
}
