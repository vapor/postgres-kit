import PostgresNIO
import Logging
import SQLKit

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

extension _PostgresSQLDatabase: SQLDatabase {
    var logger: Logger { self.database.logger }
    var eventLoop: EventLoop { self.database.eventLoop }
    var dialect: SQLDialect { PostgresDialect() }
    
    func execute(sql query: SQLExpression, _ onRow: @escaping (SQLRow) -> ()) -> EventLoopFuture<Void> {
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
}
