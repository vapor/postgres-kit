import NIOSSL
import Foundation
import NIOCore
import PostgresNIO

/// Provides configuration paramters for establishing PostgreSQL database connections.
public struct SQLPostgresConfiguration {
    /// IANA-assigned port number for PostgreSQL
    /// `UInt16(getservbyname("postgresql", "tcp").pointee.s_port).byteSwapped`
    public static var ianaPortNumber: Int { 5432 }

    /// See ``PostgresNIO/PostgresConnection/Configuration``.
    public var coreConfiguration: PostgresConnection.Configuration

    /// Optional `search_path` to set on new connections.
    public var searchPath: [String]?

    /// Create a ``SQLPostgresConfiguration`` from a string containing a properly formatted URL.
    ///
    /// See ``init(url:)`` for details on the allowed format for connection URLs.
    public init(url: String) throws {
        guard let url = URL(string: url) else {
            throw URLError(.badURL, userInfo: [NSURLErrorFailingURLStringErrorKey: url])
        }
        try self.init(url: url)
    }
    
    /// Create a ``SQLPostgresConfiguration`` from a properly formatted URL.
    ///
    /// The allowed URL format is:
    ///
    ///     postgres://username:password@hostname:port/database?tls=mode
    ///
    /// `hostname` and `username` are required; all other components are optional. For backwards
    /// compatibility, `ssl` is treated as an alias of `tls`.
    ///
    /// The allowed `mode` values for `tls` are:
    ///   - `require` (fail to connect if the server does not support TLS)
    ///   - `true` (attempt to use TLS but continue anyway if the server doesn't support it)
    ///   - `false` (do not use TLS even if the server supports it).
    /// If `tls` is omitted entirely, the mode defaults to `true`.
    public init(url: URL) throws {
        guard let comp = URLComponents(url: url, resolvingAgainstBaseURL: true),
              comp.scheme?.hasPrefix("postgres") ?? false,
              let hostname = comp.host, let username = comp.user
        else {
            throw URLError(.badURL, userInfo: [NSURLErrorFailingURLErrorKey: url, NSURLErrorFailingURLStringErrorKey: url.absoluteString])
        }
        let password = comp.password, port = comp.port ?? Self.ianaPortNumber
        let tls: PostgresConnection.Configuration.TLS
        switch (comp.queryItems ?? []).first(where: { ["ssl", "tls"].contains($0.name.lowercased()) })?.value ?? "true" {
        case "require": tls = try .require(.init(configuration: .makeClientConfiguration()))
        case "true":  tls = try .prefer(.init(configuration: .makeClientConfiguration()))
        case "false": tls = .disable
        default: throw URLError(.badURL, userInfo: [NSURLErrorFailingURLErrorKey: url, NSURLErrorFailingURLStringErrorKey: url.absoluteString])
        }
        
        self.init(
            hostname: hostname, port: port,
            username: username, password: password,
            database: url.lastPathComponent,
            tls: tls
        )
    }
    
    /// Create a ``SQLPostgresConfiguration`` for connecting to a server with a hostname and optional port.
    ///
    /// This specifies a TCP connection. If you're unsure which kind of connection you want, you almost
    /// definitely want this one.
    public init(
        hostname: String, port: Int = Self.ianaPortNumber,
        username: String, password: String? = nil,
        database: String? = nil,
        tls: PostgresConnection.Configuration.TLS
    ) {
        self.init(coreConfiguration: .init(host: hostname, port: port, username: username, password: password, database: database, tls: tls))
    }
    
    /// Create a ``SQLPostgresConfiguration`` for connecting to a server through a UNIX domain socket.
    public init(
        unixDomainSocketPath: String,
        username: String, password: String? = nil,
        database: String? = nil
    ) {
        self.init(coreConfiguration: .init(unixSocketPath: unixDomainSocketPath, username: username, password: password, database: database))
    }
    
    /// Create a ``SQLPostgresConfiguration`` for establishing a connection to a server over a
    /// preestablished `NIOCore/Channel`.
    ///
    /// This is provided for calling code which wants to manage the underlying connection transport on its
    /// own, such as when tunneling a connection through SSH.
    public init(
        establishedChannel: Channel,
        username: String, password: String? = nil,
        database: String? = nil
    ) {
        self.init(coreConfiguration: .init(establishedChannel: establishedChannel, username: username, password: password, database: database))
    }

    public init(
        coreConfiguration: PostgresConnection.Configuration,
        searchPath: [String]? = nil
    ) {
        self.coreConfiguration = coreConfiguration
        self.searchPath = searchPath
    }
}
