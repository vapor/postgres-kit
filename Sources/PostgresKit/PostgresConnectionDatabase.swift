import PostgresNIO
import SQLKit

extension PostgresConnection {
    @inlinable
    public func sql(queryLogLevel: Logger.Level? = .debug, logger: Logger? = nil) -> some SQLDatabase {
        self.sql(encodingContext: .default, decodingContext: .default, queryLogLevel: queryLogLevel, logger: logger)
    }

    public func sql(
        encodingContext: PostgresEncodingContext<some PostgresJSONEncoder>,
        decodingContext: PostgresDecodingContext<some PostgresJSONDecoder>,
        queryLogLevel: Logger.Level? = .debug,
        logger: Logger? = nil,
    ) -> some SQLDatabase {
        PostgresConnectionSQLDatabase(
            connection: self, 
            encodingContext: encodingContext, 
            decodingContext: decodingContext,
            queryLogLevel: queryLogLevel,
            _logger: logger
        )
    }
}

private struct PostgresConnectionSQLDatabase<E: PostgresJSONEncoder, D: PostgresJSONDecoder> {
    let connection: PostgresConnection
    let encodingContext: PostgresEncodingContext<E>
    let decodingContext: PostgresDecodingContext<D>
    let queryLogLevel: Logger.Level?
    let _logger: Logger?
}

extension PostgresConnectionSQLDatabase: SQLDatabase {
    var logger: Logger {
        self._logger ?? connection.logger
    }

    var eventLoop: any EventLoop {
        connection.eventLoop
    }

    var dialect: any SQLDialect {
        PostgresDialect()
    }

    func execute(sql query: any SQLExpression, _ onRow: @escaping @Sendable (any SQLRow) -> ()) -> NIOCore.EventLoopFuture<Void> {
        let (sql, binds) = self.serialize(query)

        if let queryLogLevel = self.queryLogLevel {
            self.logger.log(level: queryLogLevel, "Executing query", metadata: ["sql": .string(sql), "binds": .array(binds.map { .string("\($0)") })])
        }
        return self.eventLoop.makeCompletedFuture {
            try makeBindings(from: binds)
        }.flatMap { bindings in
            connection.query(.init(unsafeSQL: sql, binds: bindings), logger: self.logger) {
                onRow($0.sql(decodingContext: self.decodingContext))
            }
        }.map { _ in }
    }

    func execute(sql query: any SQLExpression, _ onRow: @escaping @Sendable (any SQLRow) -> ()) async throws {
        let (sql, binds) = self.serialize(query)

        if let queryLogLevel = self.queryLogLevel {
            self.logger.log(level: queryLogLevel, "Executing query", metadata: ["sql": .string(sql), "binds": .array(binds.map { .string("\($0)") })])
        }

        let bindings = try makeBindings(from: binds)

        let result = try await connection.query(.init(unsafeSQL: sql, binds: bindings), logger: logger)
        for try await row in result {
            onRow(row.sql(decodingContext: decodingContext))
        }
    }

    func makeBindings(from binds: [any Encodable & Sendable]) throws -> PostgresBindings {
        var bindings = PostgresBindings(capacity: binds.count)
        for bind in binds {
            try PostgresDataTranslation.encode(value: bind, in: self.encodingContext, to: &bindings)
        }
        return bindings
    }

    func withSession<R>(_ closure: @escaping @Sendable (any SQLDatabase) async throws -> R) async throws -> R {
        try await closure(self)
    }
}
