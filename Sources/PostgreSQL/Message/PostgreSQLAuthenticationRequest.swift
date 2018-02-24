import Foundation

/// Authentication request returned by the server.
enum PostgreSQLAuthenticationRequest: Decodable {
    /// AuthenticationOk
    case ok
    /// AuthenticationCleartextPassword
    case plaintext
    /// AuthenticationMD5Password
    case md5(Data)

    /// See `Decodable.init(from:)`
    init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        let type = try single.decode(PostgreSQLAuthenticationType.self)
        switch type {
        case .ok: self = .ok
        case .plaintext: self = .plaintext
        case .md5:
            let salt = try single.decode(Int32.self)
            self = .md5(salt.data)
        }
    }
}

/// Supported authentication types.
enum PostgreSQLAuthenticationType: Int32, Decodable {
    /// Specifies that the authentication was successful.
    case ok = 0
    /// Specifies that a clear-text password is required.
    case plaintext = 3
    /// Specifies that an MD5-encrypted password is required.
    case md5 = 5
}

extension PostgreSQLAuthenticationType: CustomStringConvertible {
    /// CustomStringConvertible.description
    var description: String {
        switch self {
        case .ok: return "none"
        case .plaintext: return "plaintext password required"
        case .md5: return "md5-hashed password required"
        }
    }
}
