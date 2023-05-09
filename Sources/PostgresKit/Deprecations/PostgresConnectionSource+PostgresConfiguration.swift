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
        self.init(sqlConfiguration: .init(legacyConfiguration: configuration))
    }
}

extension SQLPostgresConfiguration {
    // N.B.: This is public only for the sake of deprecated support in FluentPostgresDriver. Don't use it.
    @available(*, deprecated, message: "This initializer is not intended for public use. Stop using `PostgresConfigration`.")
    public init(legacyConfiguration configuration: PostgresConfiguration) {
        if let hostname = configuration._hostname, let port = configuration._port {
            self.init(
                hostname: hostname, port: port,
                username: configuration.username, password: configuration.password,
                database: configuration.database,
                tls: configuration.tlsConfiguration.flatMap { try? .require(.init(configuration: $0)) } ?? .disable
            )
            self.coreConfiguration.options.requireBackendKeyData = configuration.requireBackendKeyData
            self.searchPath = configuration.searchPath
        } else if let address = try? configuration.address(), let socketPath = address.pathname {
            self.init(
                unixDomainSocketPath: socketPath,
                username: configuration.username, password: configuration.password,
                database: configuration.database
            )
            self.coreConfiguration.options.requireBackendKeyData = configuration.requireBackendKeyData
            self.searchPath = configuration.searchPath
        } else {
            fatalError("Nonsensical legacy configuration format")
        }
    }
}
