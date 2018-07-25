import NIOOpenSSL

extension PostgreSQLConnection {
    /// Transport-layer security configuration for the PostgreSQL connection.
    public struct TransportConfig {
        /// Does not attempt to enable TLS (this is the default).
        public static var cleartext: TransportConfig {
            return .init(method: .cleartext)
        }
        
        /// Enables TLS requiring a minimum version of TLS v1.1 on the server, but disables certificate verification.
        /// This is what you would commonly use for paid Heroku PostgreSQL plans.
        public static var unverifiedTLS: TransportConfig {
            return .init(method: .tls(.forClient(certificateVerification: .none)))
        }
        
        /// Enables TLS requiring a minimum version of TLS v1.1 on the server.
        public static var standardTLS: TransportConfig {
            return .init(method: .tls(.forClient()))
        }
        
        /// Enables TLS requiring a minimum version of TLS v1.2 on the server.
        public static var modernTLS: TransportConfig {
            return .init(method: .tls(.forClient(minimumTLSVersion: .tlsv12)))
        }
        
        /// Enables TLS requiring a minimum version of TLS v1.3 on the server.
        /// TLS v1.3 specification is still a draft and unlikely to be supported by most servers.
        /// See https://tools.ietf.org/html/draft-ietf-tls-tls13-28 for more info.
        public static var edgeTLS: TransportConfig {
            return .init(method: .tls(.forClient(minimumTLSVersion: .tlsv13)))
        }
        
        /// Enables TLS using the given `TLSConfiguration`.
        /// - parameter tlsConfiguration: See `TLSConfiguration` for more info.
        public static func customTLS(_ tlsConfiguration: TLSConfiguration)-> TransportConfig {
            return .init(method: .tls(tlsConfiguration))
        }
        
        /// Returns `true` if this configuration uses TLS.
        public var isTLS: Bool {
            switch storage {
            case .cleartext: return false
            case .tls: return true
            }
        }
        
        /// Internal storage type.
        internal enum Storage {
            case cleartext
            case tls(TLSConfiguration)
        }
        
        /// Internal storage.
        internal let storage: Storage
        
        /// Internal init.
        internal init(method: Storage) {
            self.storage = method
        }
    }
    
    /// Ask the server if it supports SSL and adds a new OpenSSLClientHandler to pipeline if it does
    /// This will throw an error if the server does not support SSL
    internal func addSSLClientHandler(using tlsConfiguration: TLSConfiguration) -> Future<Void> {
        return queue.enqueue([.sslSupportRequest(.init())]) { message in
            guard case .sslSupportResponse(let response) = message else {
                throw PostgreSQLError(identifier: "SSL support check", reason: "Unsupported message encountered during SSL support check: \(message).")
            }
            guard response == .supported else {
                throw PostgreSQLError(identifier: "SSL support check", reason: "tlsConfiguration given in PostgresSQLConfiguration, but SSL connection not supported by PostgreSQL server.")
            }
            return true
        }.flatMap {
            let sslContext = try SSLContext(configuration: tlsConfiguration)
            let handler = try OpenSSLClientHandler(context: sslContext)
            return self.channel.pipeline.add(handler: handler, first: true)
        }
    }
}

