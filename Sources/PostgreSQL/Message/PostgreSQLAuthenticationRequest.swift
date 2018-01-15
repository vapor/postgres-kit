/// Authentication request returned by the server.
enum PostgreSQLAuthenticationRequest: Decodable {
    /// Specifies that the authentication was successful.
    case ok

    /// Specifies that a clear-text password is required.
    case plaintext

    /// See Decodable.init
    init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        let type = try single.decode(Int32.self)
        switch type {
        case 0: self = .ok
        case 3: self = .plaintext
        default: fatalError("Unsupported auth method: \(type)")
        }
    }
}

extension PostgreSQLAuthenticationRequest: CustomStringConvertible {
    /// CustomStringConvertible.description
    var description: String {
        switch self {
        case .ok: return "none"
        case .plaintext: return "plaintext password required"
        }
    }
}
