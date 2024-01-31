import NIOSSL
import Foundation
import NIOCore
import PostgresNIO

/// Provides configuration paramters for establishing PostgreSQL database connections.
public struct SQLPostgresConfiguration {
    /// IANA-assigned port number for PostgreSQL
    /// `UInt16(getservbyname("postgresql", "tcp").pointee.s_port).byteSwapped`
    public static var ianaPortNumber: Int { 5432 }

    // See `PostgresNIO.PostgresConnection.Configuration`.
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
    /// The supported URL formats are:
    ///
    ///     postgres://username:password@hostname:port/database?tlsmode=mode
    ///     postgres+tcp://username:password@hostname:port/database?tlsmode=mode
    ///     postgres+uds://username:password@localhost/path?tlsmode=mode#database
    ///
    /// The `postgres+tcp` scheme requests a connection over TCP. The `postgres` scheme is an alias
    /// for `postgres+tcp`. Only the `hostname` and `username` components are required.
    ///
    /// The `postgres+uds` scheme requests a connection via a UNIX domain socket. The `username` and
    /// `path` components are required. The authority must always be empty or `localhost`, and may not
    /// specify a port.
    ///
    /// The allowed `mode` values for `tlsmode` are:
    ///
    /// Value|Behavior
    /// -|-
    /// `disable`|Don't use TLS, even if the server supports it.
    /// `prefer`|Use TLS if possible.
    /// `require`|Enforce TLS support.
    ///
    /// If no `tlsmode` is specified, the default mode is `prefer` for TCP connections, or `disable`
    /// for UDS connections. If more than one mode is specified, the last one wins. Whenever a TLS
    /// connection is made, full certificate verification (both chain of trust and hostname match)
    /// is always enforced, regardless of the mode used.
    ///
    /// For compatibility with `libpq` and previous versions of this package, any of "`sslmode`",
    /// "`tls`", or "`ssl`" may be used instead of "`tlsmode`". There are also various aliases for
    /// each of the TLS mode names, as follows:
    ///
    /// - "`disable`": "`false`"
    /// - "`prefer`": "`allow`", "`true`"
    /// - "`require`": "`verify-ca`", "`verify-full`"
    ///
    /// The aliases always have the same semantics as the "canonical" modes, despite any differences
    /// suggested by their names.
    ///
    /// Also for compatibility, the URL scheme may also be `postgresql` or `postgresql+uds`.
    ///
    /// > Note: It is possible to emulate `libpq`'s definitions for `prefer` (TLS if available with
    /// > no certificate verification), `require` (TLS enforced, but also without certificate
    /// > verification) and `verify-ca` (TLS enforced with no hostname verification) by manually
    /// > specifying the TLS configuration instead of using a URL. It is not possible, by design, to
    /// > emulate `libpq`'s `allow` mode (TLS only if there is no alternative). It is _strongly_
    /// > recommended for both security and privacy reasons to always leave full certificate
    /// > verification enabled whenever possible. See NIOSSL's [`TLSConfiguration`](tlsconfig) for
    /// > additional information and recommendations.
    ///
    /// [tlsconfig]:
    /// https://swiftpackageindex.com/apple/swift-nio-ssl/main/documentation/niossl/tlsconfiguration
    public init(url: URL) throws {
        guard let comp = URLComponents(url: url, resolvingAgainstBaseURL: true), let username = comp.user else {
            throw URLError(.badURL, userInfo: [NSURLErrorFailingURLErrorKey: url, NSURLErrorFailingURLStringErrorKey: url.absoluteString])
        }
        
        func decideTLSConfig(from queryItems: [URLQueryItem], defaultMode: String) throws -> PostgresConnection.Configuration.TLS {
            switch queryItems.last(where: { ["tlsmode", "sslmode", "ssl", "tls"].contains($0.name.lowercased()) })?.value ?? defaultMode {
            case "verify-full", "verify-ca", "require":
                return try .require(.init(configuration: .makeClientConfiguration()))
            case "prefer", "allow", "true":
                return try .prefer(.init(configuration: .makeClientConfiguration()))
            case "disable", "false":
                return .disable
            default:
                throw URLError(.badURL, userInfo: [NSURLErrorFailingURLErrorKey: url, NSURLErrorFailingURLStringErrorKey: url.absoluteString])
            }
        }
        
        switch comp.scheme {
        case "postgres", "postgres+tcp", "postgresql", "postgresql+tcp":
            guard let hostname = comp.host, !hostname.isEmpty else {
                throw URLError(.badURL, userInfo: [NSURLErrorFailingURLErrorKey: url, NSURLErrorFailingURLStringErrorKey: url.absoluteString])
            }
            self.init(
                hostname: hostname, port: comp.port ?? Self.ianaPortNumber,
                username: username, password: comp.password,
                database: url.lastPathComponent.isEmpty ? nil : url.lastPathComponent,
                tls: try decideTLSConfig(from: comp.queryItems ?? [], defaultMode: "prefer")
            )
        case "postgres+uds", "postgresql+uds":
            guard (comp.host?.isEmpty ?? true || comp.host == "localhost"), comp.port == nil, !comp.path.isEmpty, comp.path != "/" else {
                throw URLError(.badURL, userInfo: [NSURLErrorFailingURLErrorKey: url, NSURLErrorFailingURLStringErrorKey: url.absoluteString])
            }
            var coreConfig = PostgresConnection.Configuration(unixSocketPath: comp.path, username: username, password: comp.password, database: comp.fragment)
            coreConfig.tls = try decideTLSConfig(from: comp.queryItems ?? [], defaultMode: "disable")
            self.init(coreConfiguration: coreConfig)
        default:
            throw URLError(.badURL, userInfo: [NSURLErrorFailingURLErrorKey: url, NSURLErrorFailingURLStringErrorKey: url.absoluteString])
        }
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
        establishedChannel: any Channel,
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
