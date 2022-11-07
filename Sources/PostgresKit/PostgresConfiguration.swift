@_exported import struct Foundation.URL

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
        
        guard let percentEncodingURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        guard let percentEncodedURL = URL(string: percentEncodingURL) else {
            return nil
        }
        
        self.init(url: percentEncodedURL)
    }
    
    public init?(url: URL) {
        
        guard url.scheme?.hasPrefix("postgres") == true else {
            return nil
        }
        
        guard let hostname = url.host else {
            return nil
        }
        
        let port = url.port ?? Self.ianaPortNumber
        
        guard let username = url.user?.removingPercentEncoding else {
            return nil
        }
        
        let password = url.password?.removingPercentEncoding
        
        let databasse = url.path.split(separator: "/", omittingEmptySubsequences: false).last.flatMap(String.init)
        
        let tlsConfiguration: TLSConfiguration?
        if url.query?.contains("ssl=true") == true || url.query?.contains("sslmode=require") == true {
            tlsConfiguration = TLSConfiguration.makeClientConfiguration()
        } else {
            tlsConfiguration = nil
        }
        
        self.init(
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            database: databasse,
            tlsConfiguration: tlsConfiguration
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
