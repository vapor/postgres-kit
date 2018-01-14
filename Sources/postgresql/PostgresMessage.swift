import Bits

enum PostgresMessage {
    case startupMessage(
        /// The protocol version number. The most significant 16 bits are the major
        /// version number (3 for the protocol described here). The least significant
        /// 16 bits are the minor version number (0 for the protocol described here).
        protocolVersion: Int32,
        /// The protocol version number is followed by one or more pairs of parameter
        /// name and value strings. A zero byte is required as a terminator after
        /// the last name/value pair. Parameters can appear in any order. user is required,
        /// others are optional. Each parameter is specified as:
        parameters: [String: String]
    )


    /// The first byte of a message identifies the message type
    var identifier: Byte? {
        switch self {
        case .startupMessage: return nil
        }
    }
}
