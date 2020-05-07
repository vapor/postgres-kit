@_exported import struct Foundation.URL

public struct PostgresConfiguration {
    public var address: () throws -> SocketAddress
    public var username: String
    public var password: String?
    public var database: String?
    public var tlsConfiguration: TLSConfiguration?

    /// Optional `search_path` to set on new connections.
    public var searchPath: [String]?

    internal var _hostname: String?


    public init?(url: String, tlsConfiguration: TLSConfiguration? = nil) {
        guard let url = URL(string: url) else {
            return nil
        }
        self.init(url: url, tlsConfiguration: tlsConfiguration)
    }
    
    public init?(url: URL, tlsConfiguration tlsConfig: TLSConfiguration? = nil) {
        guard url.scheme?.hasPrefix("postgres") == true else {
            return nil
        }
        guard let username = url.user else {
            return nil
        }
        let password = url.password
        guard let hostname = url.host else {
            return nil
        }
        let port = url.port ?? 5432

        var tlsConfiguration = tlsConfig
        if tlsConfiguration == nil, url.query?.contains("ssl=true") == true || url.query?.contains("sslmode=require") == true {
            tlsConfiguration = TLSConfiguration.forClient()
        }
        
        self.init(
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            database: url.path.split(separator: "/").last.flatMap(String.init),
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
    }
    
    public init(
        hostname: String,
        port: Int = 5432,
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
    }
}
