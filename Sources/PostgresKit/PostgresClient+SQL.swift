import PostgresNIO
import Foundation
import SQLKit

extension PostgresDatabase {
    public func sql(encoder: PostgresDataEncoder) -> SQLDatabase { self.sql(encoder: encoder, decoder: .init()) }
    public func sql(decoder: PostgresDataDecoder) -> SQLDatabase { self.sql(encoder: .init(), decoder: decoder) }
    public func sql(encoder: PostgresDataEncoder, decoder: PostgresDataDecoder) -> SQLDatabase {
        _PostgresSQLDatabase(database: self,
            encodingContext: encoder.underlyingContext,
            decodingContext: decoder.underlyingContext
        )
    }
    
    public func sql<E: PostgresJSONEncoder, D: PostgresJSONDecoder>(
        jsonEncoder: E, jsonDecoder: D
    ) -> SQLDatabase {
        _PostgresSQLDatabase(database: self,
            encodingContext: .init(jsonEncoder: jsonEncoder),
            decodingContext: .init(jsonDecoder: jsonDecoder)
        )
    }
    
    public func sql() -> SQLDatabase {
        _PostgresSQLDatabase(database: self, encodingContext: .default, decodingContext: .default)
    }
}

// MARK: Private

private struct _PostgresSQLDatabase<E: PostgresJSONEncoder, D: PostgresJSONDecoder> {
    let database: PostgresDatabase
    let encodingContext: PostgresEncodingContext<E>
    let decodingContext: PostgresDecodingContext<D>
}

extension _PostgresSQLDatabase: SQLDatabase {
    var logger: Logger { self.database.logger }
    var eventLoop: EventLoop { self.database.eventLoop }
    var dialect: SQLDialect { PostgresDialect() }
    
    func execute(sql query: SQLExpression, _ onRow: @escaping (SQLRow) -> ()) -> EventLoopFuture<Void> {
        let (sql, binds) = self.serialize(query)
        
        return self.eventLoop.makeCompletedFuture {
            var bindings = PostgresBindings(capacity: binds.count)
            for bind in binds {
                if let encodableBind = bind as? PostgresNonThrowingEncodable { bindings.append(encodableBind, context: self.encodingContext) }
                else if let encodableBind = bind as? PostgresEncodable { try bindings.append(encodableBind, context: self.encodingContext) }
                else { try bindings.append(PostgresDataEncoder(json: self.encodingContext.jsonEncoder).encode(bind)) }
            }
            return bindings
        }.flatMap { bindings in self.database.withConnection {
            $0.query(
                .init(unsafeSQL: sql, binds: bindings),
                logger: $0.logger,
                { onRow($0.sql(decoder: .init(json: self.decodingContext.jsonDecoder))) }
            )
        } }.map { _ in }
    }
}
