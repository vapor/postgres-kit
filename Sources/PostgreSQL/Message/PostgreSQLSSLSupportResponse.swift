import Core

/// Response given after sending a PostgreSQLSSLSupportRequest
/// For more info, see https://www.postgresql.org/docs/10/static/protocol-flow.html#id-1.10.5.7.11
enum PostgreSQLSSLSupportResponse: UInt8, Decodable {
    case supported = 0x53
    case notSupported = 0x4E
}
