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
        
        let tlsConfiguration: TLSConfiguration?
        if url.query == "ssl=true" {
            tlsConfiguration = TLSConfiguration.forClient(certificateVerification: .none)
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
        hostname: String,
        port: Int = 5432,
        username: String,
        password: String,
        database: String? = nil,
        tlsConfiguration: TLSConfiguration? = nil,
        encoder: PostgresDataEncoder = PostgresDataEncoder(jsonEncoder: JSONEncoder()),
        decoder: PostgresDataDecoder = PostgresDataDecoder(jsonDecoder: JSONDecoder())
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
