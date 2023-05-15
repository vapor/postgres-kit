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

extension _PostgresSQLDatabase: SQLDatabase, PostgresDatabase {
    var logger: Logger { self.database.logger }
    var eventLoop: any EventLoop { self.database.eventLoop }
    var version: (any SQLDatabaseReportedVersion)? { nil } // PSQL doesn't send version in wire protocol, must use SQL to read it
    var dialect: any SQLDialect { PostgresDialect() }
    
    func execute(sql query: any SQLExpression, _ onRow: @escaping (any SQLRow) -> ()) -> EventLoopFuture<Void> {
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
        .flatMapErrorThrowing { try PostgresDataTranslation.applyPSQLErrorBandaidIfNeeded(for: $0) }
    }
    
    func withConnection<T>(_ closure: @escaping (PostgresConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection(closure)
        .flatMapErrorThrowing { try PostgresDataTranslation.applyPSQLErrorBandaidIfNeeded(for: $0) }
    }
}

// This can go away as soon as https://github.com/vapor/postgres-nio/pull/360 is merged.
struct ExpressivePSQLError: Error, CustomStringConvertible, CustomDebugStringConvertible {
    let underlyingError: PSQLError
    var description: String { "Database error" }
    var debugDescription: String {
        var desc = #"PSQLError(code: \#(self.underlyingError.code)"#
        if let serverInfo = self.underlyingError.serverInfo {
            desc.append(", serverInfo: [")
            desc.append(["localizedSeverity": PSQLError.ServerInfo.Field.localizedSeverity, "severity": .severity, "sqlState": .sqlState, "message": .message, "detail": .detail, "hint": .hint, "position": .position, "internalPosition": .internalPosition, "internalQuery": .internalQuery, "locationContext": .locationContext, "schemaName": .schemaName, "tableName": .tableName, "columnName": .columnName, "dataTypeName": .dataTypeName, "constraintName": .constraintName, "file": .file, "line": .line, "routine": .routine].compactMap { name, field in serverInfo[field].map { "\(name): \($0)" } }.joined(separator: ", "))
            desc.append("]")
        }
        if let underlying = self.underlyingError.underlying { desc.append(", underlying: \(String(reflecting: underlying))") }
        if let file = self.underlyingError.file {
            desc.append(", triggeredFromRequestInFile: \(file)")
            if let line = self.underlyingError.line { desc.append(", line: \(line)") }
        }
        if let query = self.underlyingError.query { desc.append(", query: \(query)") }
        desc.append(")")
        return desc
    }
}

extension PostgresDataTranslation {
    @usableFromInline
    static func applyPSQLErrorBandaidIfNeeded(for error: any Error) throws -> Never {
        if let psqlError = error as? PSQLError {
            throw ExpressivePSQLError(underlyingError: psqlError)
        } else {
            throw error
        }
    }
}
