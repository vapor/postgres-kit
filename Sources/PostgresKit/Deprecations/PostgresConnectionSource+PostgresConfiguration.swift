import NIOSSL
import Atomics
import AsyncKit
import Logging
import PostgresNIO
import NIOCore

extension PostgresConnectionSource {
    @available(*, deprecated, message: "Use `sqlConfiguration` instead.")
    public var configuration: PostgresConfiguration {
        if let hostname = self.sqlConfiguration.coreConfiguration.host,
           let port = self.sqlConfiguration.coreConfiguration.port
        {
            var oldConfig = PostgresConfiguration(
                hostname: hostname, port: port,
                username: self.sqlConfiguration.coreConfiguration.username, password: self.sqlConfiguration.coreConfiguration.password,
                database: self.sqlConfiguration.coreConfiguration.database,
                tlsConfiguration: self.sqlConfiguration.coreConfiguration.tls.sslContext.map { _ in .makeClientConfiguration() }
            )
            oldConfig.requireBackendKeyData = self.sqlConfiguration.coreConfiguration.options.requireBackendKeyData
            oldConfig.searchPath = self.sqlConfiguration.searchPath
            return oldConfig
        } else if let socketPath = self.sqlConfiguration.coreConfiguration.unixSocketPath {
            var oldConfig = PostgresConfiguration(
                unixDomainSocketPath: socketPath,
                username: self.sqlConfiguration.coreConfiguration.username, password: self.sqlConfiguration.coreConfiguration.password,
                database: self.sqlConfiguration.coreConfiguration.database
            )
            oldConfig.requireBackendKeyData = self.sqlConfiguration.coreConfiguration.options.requireBackendKeyData
            oldConfig.searchPath = self.sqlConfiguration.searchPath
            return oldConfig
        } else {
            return .init(hostname: "<invalid>", port: 0, username: "", password: nil, database: nil, tlsConfiguration: nil)
        }
    }
    
    @available(*, deprecated, message: "Use `sqlConfiguration` instead.")
    public var sslContext: Result<NIOSSLContext?, Error> { .success(self.sqlConfiguration.coreConfiguration.tls.sslContext) }
    
    @available(*, deprecated, message: "Use `init(sqlConfiguration:)` instead.")
    public init(configuration: PostgresConfiguration) {
        if let hostname = configuration._hostname, let port = configuration._port {
            var config = SQLPostgresConfiguration(
                hostname: hostname, port: port,
                username: configuration.username, password: configuration.password,
                database: configuration.database,
                tls: configuration.tlsConfiguration.flatMap { try? .require(.init(configuration: $0)) } ?? .disable
            )
            config.coreConfiguration.options.requireBackendKeyData = configuration.requireBackendKeyData
            config.searchPath = configuration.searchPath
            self.init(sqlConfiguration: config)
        } else if let address = try? configuration.address(), let socketPath = address.pathname {
            var config = SQLPostgresConfiguration(
                unixDomainSocketPath: socketPath,
                username: configuration.username, password: configuration.password,
                database: configuration.database
            )
            config.coreConfiguration.options.requireBackendKeyData = configuration.requireBackendKeyData
            config.searchPath = configuration.searchPath
            self.init(sqlConfiguration: config)
        } else {
            fatalError("Nonsensical legacy configuration format")
        }
    }
}
