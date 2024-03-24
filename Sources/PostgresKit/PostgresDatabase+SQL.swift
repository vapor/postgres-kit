import PostgresNIO
import Logging
@preconcurrency import SQLKit

// https://github.com/vapor/postgres-nio/pull/450
#if compiler(>=5.10) && $RetroactiveAttribute
extension PostgresEncodingContext: @retroactive @unchecked Sendable {}
#else
extension PostgresEncodingContext: @unchecked Sendable {}
#endif

extension PostgresDatabase {
    @inlinable
    public func sql(queryLogLevel: Logger.Level? = .debug) -> some SQLDatabase {
        self.sql(encodingContext: .default, decodingContext: .default, queryLogLevel: queryLogLevel)
    }
    
    public func sql(
        encodingContext: PostgresEncodingContext<some PostgresJSONEncoder>,
        decodingContext: PostgresDecodingContext<some PostgresJSONDecoder>,
        queryLogLevel: Logger.Level? = .debug
    ) -> some SQLDatabase {
        _PostgresSQLDatabase(database: self, encodingContext: encodingContext, decodingContext: decodingContext, queryLogLevel: queryLogLevel)
    }
}

private struct _PostgresSQLDatabase<PDatabase: PostgresDatabase, E: PostgresJSONEncoder, D: PostgresJSONDecoder> {
    let database: PDatabase
    let encodingContext: PostgresEncodingContext<E>
    let decodingContext: PostgresDecodingContext<D>
    let queryLogLevel: Logger.Level?
    
    init(database: PDatabase, encodingContext: PostgresEncodingContext<E>, decodingContext: PostgresDecodingContext<D>, queryLogLevel: Logger.Level?) {
        self.database = database
        self.encodingContext = encodingContext
        self.decodingContext = decodingContext
        self.queryLogLevel = queryLogLevel
    }
}

extension _PostgresSQLDatabase: SQLDatabase, PostgresDatabase {
    var logger: Logger {
        self.database.logger
    }
    
    var eventLoop: any EventLoop {
        self.database.eventLoop
    }
    
    var version: (any SQLDatabaseReportedVersion)? {
        nil  // PSQL doesn't send version in wire protocol, must use SQL to read it
    }
    
    var dialect: any SQLDialect {
        PostgresDialect()
    }
    
    func execute(sql query: any SQLExpression, _ onRow: @escaping @Sendable (any SQLRow) -> ()) -> EventLoopFuture<Void> {
        let (sql, binds) = self.serialize(query)
        
        if let queryLogLevel {
            self.logger.log(level: queryLogLevel, "\(sql) [\(binds)]")
        }
        return self.eventLoop.makeCompletedFuture {
            var bindings = PostgresBindings(capacity: binds.count)
            for bind in binds {
                try PostgresDataTranslation.encode(value: bind, in: self.encodingContext, to: &bindings)
            }
            return bindings
        }.flatMap { bindings in self.database.withConnection {
            $0.query(
                .init(unsafeSQL: sql, binds: bindings),
                logger: $0.logger,
                { onRow($0.sql(decodingContext: self.decodingContext)) }
            )
        } }.map { _ in }
    }
    
    func send(_ request: any PostgresRequest, logger: Logger) -> EventLoopFuture<Void> {
        self.database.send(request, logger: logger)
    }
    
    func withConnection<T>(_ closure: @escaping (PostgresConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection(closure)
    }
}
