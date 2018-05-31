/// Identifies the message as a password response. Note that this is also used for
/// GSSAPI and SSPI response messages (which is really a design error, since the contained
/// data is not a null-terminated string in that case, but can be arbitrary binary data).
struct PostgreSQLPasswordMessage: Encodable {
    /// The password (encrypted, if requested).
    var password: String
}
