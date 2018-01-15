import Bits

/// Identifies the message as a Close command.
struct PostgreSQLCloseCommand: Decodable {
    /// 'S' to close a prepared statement; or 'P' to close a portal.
    var type: Byte

    /// The name of the prepared statement or portal to close (an empty string selects the unnamed prepared statement or portal).
    var name: String

    /// See Decodable.init
    init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        type = try single.decode(Byte.self)
        name = try single.decode(String.self)
    }
}
