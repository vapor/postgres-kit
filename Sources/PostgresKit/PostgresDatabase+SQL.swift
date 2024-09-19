import PostgresNIO
import Dispatch
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
        PostgresSQLDatabase(database: self, encodingContext: encodingContext, decodingContext: decodingContext, queryLogLevel: queryLogLevel)
    }
}

private struct PostgresSQLDatabase<PDatabase: PostgresDatabase, E: PostgresJSONEncoder, D: PostgresJSONDecoder> {
    let database: PDatabase
    let encodingContext: PostgresEncodingContext<E>
    let decodingContext: PostgresDecodingContext<D>
    let queryLogLevel: Logger.Level?
}

extension PostgresSQLDatabase: SQLDatabase, PostgresDatabase {
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
        
        if let queryLogLevel = self.queryLogLevel {
            self.logger.log(level: queryLogLevel, "Executing query", metadata: ["sql": .string(sql), "binds": .array(binds.map { .string("\($0)") })])
        }
        
        let startTime = DispatchTime.now()
        
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
        } }.map { _ in
            if let queryLogLevel = self.queryLogLevel {
                let executionTime = Int(DispatchTime.now().uptimeNanoseconds / UInt64(1_000_000) 
                                        - startTime.uptimeNanoseconds / UInt64(1_000_000))
                self.logger.log(level: queryLogLevel, "Query executed in \(executionTime) ms",
                                metadata: ["sql": .string(sql),
                                           "binds": .array(binds.map { .string("\($0)") }),
                                           "execution_time_ms" : .stringConvertible(executionTime)])
            }
        }
    }
    
    func execute(
        sql query: any SQLExpression,
        _ onRow: @escaping @Sendable (any SQLRow) -> ()
    ) async throws {
        let (sql, binds) = self.serialize(query)
        
        if let queryLogLevel = self.queryLogLevel {
            self.logger.log(level: queryLogLevel, "Executing query", metadata: ["sql": .string(sql), "binds": .array(binds.map { .string("\($0)") })])
        }

        let startTime = DispatchTime.now()
        
        var bindings = PostgresBindings(capacity: binds.count)
        for bind in binds {
            try PostgresDataTranslation.encode(value: bind, in: self.encodingContext, to: &bindings)
        }

        _ = try await self.database.withConnection {
            $0.query(
                .init(unsafeSQL: sql, binds: bindings),
                logger: $0.logger,
                { onRow($0.sql(decodingContext: self.decodingContext)) }
            )
        }.get()
        
        if let queryLogLevel = self.queryLogLevel {
            let executionTime = Int(DispatchTime.now().uptimeNanoseconds / UInt64(1_000_000)
                                    - startTime.uptimeNanoseconds / UInt64(1_000_000))
            self.logger.log(level: queryLogLevel, "Query executed in \(executionTime) ms",
                            metadata: ["sql": .string(sql),
                                       "binds": .array(binds.map { .string("\($0)") }),
                                       "execution_time_ms" : .stringConvertible(executionTime)])
        }
    }
    
    
    func send(_ request: any PostgresRequest, logger: Logger) -> EventLoopFuture<Void> {
        self.database.send(request, logger: logger)
    }
    
    func withConnection<T>(_ closure: @escaping (PostgresConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection(closure)
    }
    
    func withSession<R>(_ closure: @escaping @Sendable (any SQLDatabase) async throws -> R) async throws -> R {
        try await self.withConnection { c in
            c.eventLoop.makeFutureWithTask {
                try await closure(c.sql(
                    encodingContext: self.encodingContext,
                    decodingContext: self.decodingContext,
                    queryLogLevel: self.queryLogLevel
                ))
            }
        }.get()
    }
}
