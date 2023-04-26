import NIOSSL
import Foundation
import NIOCore

@available(*, deprecated, message: "Use `SQLPostgresConfiguration` instead.")
public struct PostgresConfiguration {
    public var address: () throws -> SocketAddress
    public var username: String
    public var password: String?
    public var database: String?
    public var tlsConfiguration: TLSConfiguration?

    /// Require connection to provide `BackendKeyData`.
    /// For use with Amazon RDS Proxy, this must be set to false.
    ///
    /// - Default: true
    public var requireBackendKeyData: Bool = true

    /// Optional `search_path` to set on new connections.
    public var searchPath: [String]?

    /// IANA-assigned port number for PostgreSQL
    /// `UInt16(getservbyname("postgresql", "tcp").pointee.s_port).byteSwapped`
    public static var ianaPortNumber: Int { 5432 }

    internal var _hostname: String?
    internal var _port: Int?

    public init?(url: String) {
        guard let url = URL(string: url) else {
            return nil
        }
        self.init(url: url)
    }
    
    public init?(url: URL) {
        guard let comp = URLComponents(url: url, resolvingAgainstBaseURL: true),
              comp.scheme?.hasPrefix("postgres") ?? false,
              let hostname = comp.host, let username = comp.user
        else {
            return nil
        }
        let password = comp.password, port = comp.port ?? Self.ianaPortNumber
        let wantTLS = (comp.queryItems ?? []).contains { ["ssl=true", "sslmode=require"].contains($0.description) }
        
        self.init(
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            database: url.lastPathComponent,
            tlsConfiguration: wantTLS ? .makeClientConfiguration() : nil
        )
    }

    public init(
        unixDomainSocketPath: String,
        username: String,
        password: String? = nil,
        database: String? = nil
    ) {
        self.address = {
            return try SocketAddress.init(unixDomainSocketPath: unixDomainSocketPath)
        }
        self.username = username
        self.password = password
        self.database = database
        self.tlsConfiguration = nil
        self._hostname = nil
        self._port = nil
    }
    
    public init(
        hostname: String,
        port: Int = Self.ianaPortNumber,
        username: String,
        password: String? = nil,
        database: String? = nil,
        tlsConfiguration: TLSConfiguration? = nil
    ) {
        self.address = {
            return try SocketAddress.makeAddressResolvingHost(hostname, port: port)
        }
        self.username = username
        self.database = database
        self.password = password
        self.tlsConfiguration = tlsConfiguration
        self._hostname = hostname
        self._port = port
    }
}
