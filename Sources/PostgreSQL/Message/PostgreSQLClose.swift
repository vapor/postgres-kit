import Bits

/// Identifies the message as a Close command.
struct PostgreSQLClose: Decodable {
    /// 'S' to close a prepared statement; or 'P' to close a portal.
    var type: PostgreSQLCloseType

    /// See `Decodable.init(from:)`
    init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        let string = try single.decode(String.self)
        /// This message format is overloaded with `C` byte identifier.
        /// We need to do some checking to see what type it actually is.
        switch string.first {
        case .some(let c):
            switch c {
            case "S": type = .statement(name: String(string[string.index(after: string.startIndex)...]))
            case "P": type = .portal(name: String(string[string.index(after: string.startIndex)...]))
            default: type = .command(string)
            }
        default: type = .command(string)
        }
    }
}


enum PostgreSQLCloseType {
    /// The name of the prepared statement or portal to close (an empty string selects the unnamed prepared statement or portal).
    case statement(name: String)
    /// The name of the prepared statement or portal to close (an empty string selects the unnamed prepared statement or portal).
    case portal(name: String)
    /// The command tag. This is usually a single word that identifies which SQL command was completed.
    case command(String)
}

