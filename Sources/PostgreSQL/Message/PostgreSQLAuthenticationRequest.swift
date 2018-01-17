/// Authentication request returned by the server.
struct PostgreSQLAuthenticationRequest: Decodable {
    /// Requested auth type.
    var type: PostgreSQLAuthenticationType
}

/// Supported authentication types.
enum PostgreSQLAuthenticationType: Int32, Decodable {
    /// Specifies that the authentication was successful.
    case ok = 0
    /// Specifies that a clear-text password is required.
    case plaintext = 3
}

extension PostgreSQLAuthenticationType: CustomStringConvertible {
    /// CustomStringConvertible.description
    var description: String {
        switch self {
        case .ok: return "none"
        case .plaintext: return "plaintext password required"
        }
    }
}
