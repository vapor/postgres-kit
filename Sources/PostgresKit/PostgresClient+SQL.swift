import PostgresNIO
import SQLKit

extension PostgresDatabase {
    public func sql() -> SQLDatabase {
        _PostgresSQLDatabase(database: self, encoder: self.encoder, decoder: self.decoder)
    }
}

private struct _PostgresSQLDatabase {
    let database: PostgresDatabase
    let encoder: PostgresEncoder
    let decoder: PostgresDecoder
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
                return try self.encoder.encode(encodable)
            }) { row in
                onRow(row.sqlRow(using: self.decoder))
            }
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }
}
