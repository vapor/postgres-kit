extension EventLoopConnectionPool where Source == PostgresConnectionSource {
    public func database(logger: Logger) -> PostgresDatabase {
        _ConnectionPoolPostgresDatabase(pool: self, logger: logger)
    }
}

private struct _ConnectionPoolPostgresDatabase {
    let pool: EventLoopConnectionPool<PostgresConnectionSource>
    let logger: Logger
}

extension _ConnectionPoolPostgresDatabase: PostgresDatabase {
    var eventLoop: EventLoop { self.pool.eventLoop }
    var encoder: PostgresEncoder { self.pool.source.configuration.encoder }
    var decoder: PostgresDecoder { self.pool.source.configuration.decoder }
    
    func send(_ request: PostgresRequest, logger: Logger) -> EventLoopFuture<Void> {
        self.pool.withConnection(logger: logger) {
            $0.send(request, logger: logger)
        }
    }
    
    func withConnection<T>(_ closure: @escaping (PostgresConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.pool.withConnection(logger: self.logger, closure)
    }
}
