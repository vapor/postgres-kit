import NIOSSL
import Atomics
import AsyncKit
import Logging
import PostgresNIO
import SQLKit
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
                conn.sql(queryLogLevel: nil)
                    .raw("SET search_path TO \(idents: searchPath, joinedBy: ",")")
                    .run()
                    .map { _ in conn }
            }
        } else {
            return connectionFuture
        }
    }
}

extension PostgresConnection: ConnectionPoolItem { }
