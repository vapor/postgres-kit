import DatabaseKit
import Foundation
import NIO
import NIOPostgres
import NIOOpenSSL

public final class PostgresDatabase: Database {
    public struct Config {
        public let address: () throws -> SocketAddress
        public let username: String
        public let password: String
        public let database: String?
        public let tlsConfig: TLSConfiguration?
        
        public init?(url: URL) {
            guard url.scheme == "postgres" else {
                return nil
            }
            guard let username = url.user else {
                return nil
            }
            guard let password = url.password else {
                return nil
            }
            guard let hostname = url.host else {
                return nil
            }
            guard let port = url.port else {
                return nil
            }
            
            let tlsConfig: TLSConfiguration?
            if url.query == "ssl=true" {
                tlsConfig = TLSConfiguration.forClient(certificateVerification: .none)
            } else {
                tlsConfig = nil
            }
            
            self.init(
                hostname: hostname,
                port: port,
                username: username,
                password: password,
                database: url.databaseName,
                tlsConfig: tlsConfig
            )
        }
        
        public init(
            hostname: String,
            port: Int = 5432,
            username: String,
            password: String,
            database: String? = nil,
            tlsConfig: TLSConfiguration? = nil
        ) {
            self.address = {
                return try SocketAddress.makeAddressResolvingHost(hostname, port: port)
            }
            self.username = username
            self.database = database
            self.password = password
            self.tlsConfig = tlsConfig
        }
    }
    
    public var eventLoop: EventLoop
    public let config: Config
    
    public init(config: Config, on eventLoop: EventLoop) {
        self.config = config
        self.eventLoop = eventLoop
    }
    
    public func newConnection() -> EventLoopFuture<PostgresConnection> {
        let address: SocketAddress
        do {
            address = try self.config.address()
        } catch {
            return self.eventLoop.makeFailedFuture(error: error)
        }
        return PostgresConnection.connect(to: address, on: self.eventLoop).then { conn in
            return conn.authenticate(
                username: self.config.username,
                database: self.config.database,
                password: self.config.password
            ).map { conn }
        }.then { conn in
            if let tlsConfig = self.config.tlsConfig {
                return conn.requestTLS(using: tlsConfig).map { upgraded in
                    if !upgraded {
                        #warning("throw an error here?")
                        print("[Postgres] Server does not support TLS")
                    }
                    return conn
                }
            } else {
                return self.eventLoop.makeSucceededFuture(result: conn)
            }
        }
    }
}

extension PostgresConnection: DatabaseConnection {
    public var isClosed: Bool {
        #warning("implement is closed")
        return false
    }
}

import SQLKit

extension PostgresRow: SQLRow {
    public func decode<D>(_ type: D.Type, table: String?) throws -> D
        where D: Decodable
    {
        if let table = table {
            return try self.decode(D.self, table: table)
        } else {
            return try self.decode(D.self, tableOID: 0)
        }
    }
    
    
}

extension PostgresConnection: SQLDatabase {
    public func execute(_ query: PostgresQuery, _ onRow: @escaping (PostgresRow) throws -> ()) -> EventLoopFuture<Void> {
        var binds: [Encodable] = []
        let sql = query.serialize(&binds)
        var b = PostgresBinds()
        binds.forEach { b.encode($0) }
        return self.query(sql, b, onRow).then {
            switch query.storage {
            case .alterTable, .createTable, .dropTable:
                return self.loadTableNames()
            default:
                return self.eventLoop.makeSucceededFuture(result: ())
            }
        }
    }
}

extension PostgresDatabase: SQLDatabase {
    public func execute(_ query: PostgresQuery, _ onRow: @escaping (PostgresRow) throws -> ()) -> EventLoopFuture<Void> {
        return self.newConnection().then { conn in
            return conn.execute(query, onRow)
        }
    }
}
