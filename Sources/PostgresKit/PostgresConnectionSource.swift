import NIOSSL
import Atomics
import AsyncKit
import Logging
import PostgresNIO
import NIOCore

public struct PostgresConnectionSource: ConnectionPoolSource {
    public let sqlConfiguration: SQLPostgresConfiguration
    
    private static let idGenerator = ManagedAtomic<Int>(0)
    
    public init(sqlConfiguration: SQLPostgresConfiguration) {
        self.sqlConfiguration = sqlConfiguration
    }

    public func makeConnection(
        logger: Logger,
        on eventLoop: any EventLoop
    ) -> EventLoopFuture<PostgresConnection> {
        let connectionFuture = PostgresConnection.connect(
            on: eventLoop,
            configuration: self.sqlConfiguration.coreConfiguration,
            id: Self.idGenerator.wrappingIncrementThenLoad(ordering: .relaxed),
            logger: logger
        )
        
        if let searchPath = self.sqlConfiguration.searchPath {
            return connectionFuture.flatMap { conn in
                let string = searchPath.map { #""\#($0)""# }.joined(separator: ", ")
                return conn.simpleQuery("SET search_path = \(string)").map { _ in conn }
            }
            .flatMapErrorThrowing { try PostgresDataTranslation.applyPSQLErrorBandaidIfNeeded(for: $0) }
        } else {
            return connectionFuture
            .flatMapErrorThrowing { try PostgresDataTranslation.applyPSQLErrorBandaidIfNeeded(for: $0) }
        }
    }
}

extension PostgresConnection: ConnectionPoolItem { }
