import Foundation
import NIOOpenSSL


public struct PostgreSQLTransportConfig {
    /// Does not attempt to enable TLS (this is the default).
    public static var cleartext: PostgreSQLTransportConfig {
        return .init(method: .cleartext)
    }
    
    /// Enables TLS requiring a minimum version of TLS v1.1 on the server, but disables certificate verification.
    /// This is what you would commonly use for paid Heroku PostgreSQL plans.
    public static var unverifiedTLS: PostgreSQLTransportConfig {
        return .init(method: .tls(.forClient(certificateVerification: .none)))
    }
    
    /// Enables TLS requiring a minimum version of TLS v1.1 on the server.
    public static var standardTLS: PostgreSQLTransportConfig {
        return .init(method: .tls(.forClient()))
    }
    
    /// Enables TLS requiring a minimum version of TLS v1.2 on the server.
    public static var modernTLS: PostgreSQLTransportConfig {
        return .init(method: .tls(.forClient(minimumTLSVersion: .tlsv12)))
    }
    
    /// Enables TLS requiring a minimum version of TLS v1.3 on the server.
    /// TLS v1.3 specification is still a draft and unlikely to be supported by most servers.
    /// See https://tools.ietf.org/html/draft-ietf-tls-tls13-28 for more info.
    public static var edgeTLS: PostgreSQLTransportConfig {
        return .init(method: .tls(.forClient(minimumTLSVersion: .tlsv13)))
    }
    
    /// Enables TLS using the given `TLSConfiguration`.
    /// - parameter tlsConfiguration: See `TLSConfiguration` for more info.
    public static func customTLS(_ tlsConfiguration: TLSConfiguration)-> PostgreSQLTransportConfig {
        return .init(method: .tls(tlsConfiguration))
    }
    
    internal enum Method {
        case cleartext
        case tls(TLSConfiguration)
    }
    
    internal let method: Method
    
    internal init(method: Method) {
        self.method = method
    }
}
