import NIOCore
import PostgresNIO
import AsyncKit
import Logging

extension EventLoopGroupConnectionPool where Source == PostgresConnectionSource {
    public func database(logger: Logger) -> any PostgresDatabase {
        _EventLoopGroupConnectionPoolPostgresDatabase(pool: self, logger: logger)
    }
}

extension EventLoopConnectionPool where Source == PostgresConnectionSource {
    public func database(logger: Logger) -> any PostgresDatabase {
        _EventLoopConnectionPoolPostgresDatabase(pool: self, logger: logger)
    }
}


private struct _EventLoopGroupConnectionPoolPostgresDatabase: PostgresDatabase {
    let pool: EventLoopGroupConnectionPool<PostgresConnectionSource>
    let logger: Logger

    var eventLoop: any EventLoop { self.pool.eventLoopGroup.any() }

    func send(_ request: any PostgresRequest, logger: Logger) -> EventLoopFuture<Void> {
        self.pool.withConnection(logger: logger) { $0.send(request, logger: logger) }
    }

    func withConnection<T>(_ closure: @escaping (PostgresConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.pool.withConnection(logger: self.logger, closure)
    }
}

private struct _EventLoopConnectionPoolPostgresDatabase: PostgresDatabase {
    let pool: EventLoopConnectionPool<PostgresConnectionSource>
    let logger: Logger

    var eventLoop: any EventLoop { self.pool.eventLoop }
    
    func send(_ request: any PostgresRequest, logger: Logger) -> EventLoopFuture<Void> {
        self.pool.withConnection(logger: logger) { $0.send(request, logger: logger) }
    }
    
    func withConnection<T>(_ closure: @escaping (PostgresConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.pool.withConnection(logger: self.logger, closure)
    }
}
