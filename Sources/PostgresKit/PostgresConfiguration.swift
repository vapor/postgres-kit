@_exported import Foundation

public struct PostgresConfiguration {
    public let address: () throws -> SocketAddress
    public let username: String
    public let password: String
    public let database: String?
    public let tlsConfiguration: TLSConfiguration?

    public let encoder: PostgresDataEncoder
    public let decoder: PostgresDataDecoder

    internal var _hostname: String?
    
    public init?(url: URL) {
        guard url.scheme?.hasPrefix("postgres") == true else {
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
        
        let tlsConfiguration: TLSConfiguration?
        if url.query?.contains("ssl=true") == true || url.query?.contains("sslmode=require") == true {
            tlsConfiguration = TLSConfiguration.forClient()
        } else {
            tlsConfiguration = nil
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
        password: String,
        database: String,
        encoder: PostgresDataEncoder = PostgresDataEncoder(),
        decoder: PostgresDataDecoder = PostgresDataDecoder()
    ) {
        self.address = {
            return try SocketAddress.init(unixDomainSocketPath: unixDomainSocketPath)
        }
        self.username = username
        self.password = password
        self.database = database
        self.tlsConfiguration = nil
        self._hostname = nil
        self.encoder = encoder
        self.decoder = decoder
    }
    
    public init(
        hostname: String,
        port: Int = 5432,
        username: String,
        password: String,
        database: String? = nil,
        tlsConfiguration: TLSConfiguration? = nil,
        encoder: PostgresDataEncoder = PostgresDataEncoder(),
        decoder: PostgresDataDecoder = PostgresDataDecoder()
    ) {
        self.address = {
            return try SocketAddress.makeAddressResolvingHost(hostname, port: port)
        }
        self.username = username
        self.database = database
        self.password = password
        self.tlsConfiguration = tlsConfiguration
        self._hostname = hostname
        self.encoder = encoder
        self.decoder = decoder
    }
}
