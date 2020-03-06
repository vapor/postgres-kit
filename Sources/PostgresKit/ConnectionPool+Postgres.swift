extension EventLoopGroupConnectionPool where Source == PostgresConnectionSource {
    public func database(logger: Logger) -> PostgresDatabase {
        _EventLoopGroupConnectionPoolPostgresDatabase(pool: self, logger: logger)
    }
}

private struct _EventLoopGroupConnectionPoolPostgresDatabase {
    let pool: EventLoopGroupConnectionPool<PostgresConnectionSource>
    let logger: Logger
}

extension _EventLoopGroupConnectionPoolPostgresDatabase: PostgresDatabase {
    var eventLoop: EventLoop { self.pool.eventLoopGroup.next() }

    func send(_ request: PostgresRequest, logger: Logger) -> EventLoopFuture<Void> {
        self.pool.withConnection(logger: logger) {
            $0.send(request, logger: logger)
        }
    }

    func withConnection<T>(_ closure: @escaping (PostgresConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.pool.withConnection(logger: self.logger, closure)
    }
}

extension EventLoopConnectionPool where Source == PostgresConnectionSource {
    public func database(logger: Logger) -> PostgresDatabase {
        _EventLoopConnectionPoolPostgresDatabase(pool: self, logger: logger)
    }
}

private struct _EventLoopConnectionPoolPostgresDatabase {
    let pool: EventLoopConnectionPool<PostgresConnectionSource>
    let logger: Logger
}

extension _EventLoopConnectionPoolPostgresDatabase: PostgresDatabase {
    var eventLoop: EventLoop { self.pool.eventLoop }
    
    func send(_ request: PostgresRequest, logger: Logger) -> EventLoopFuture<Void> {
        self.pool.withConnection(logger: logger) {
            $0.send(request, logger: logger)
        }
    }
    
    func withConnection<T>(_ closure: @escaping (PostgresConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.pool.withConnection(logger: self.logger, closure)
    }
}
