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
    
    var dialect: SQLDialect {
        PostgresDialect()
    }
    
    func execute(sql query: SQLExpression, _ onRow: @escaping (SQLRow) -> ()) -> EventLoopFuture<Void> {
        let (sql, binds) = self.serialize(query)
        do {
            return try self.database.query(sql, binds.map { encodable in
                return try PostgresDataEncoder().encode(encodable)
            }) { row in
                onRow(row)
            }
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }
}
