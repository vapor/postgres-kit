/// First message sent from the frontend during startup.
struct PostgreSQLStartupMessage: Encodable {
    /// Creates a `PostgreSQLStartupMessage` with "3.0" as the protocol version.
    static func versionThree(parameters: PostgreSQLParameters) -> PostgreSQLStartupMessage {
        return .init(protocolVersion: 196608, parameters: parameters)
    }

    /// The protocol version number. The most significant 16 bits are the major
    /// version number (3 for the protocol described here). The least significant
    /// 16 bits are the minor version number (0 for the protocol described here).
    var protocolVersion: Int32

    /// The protocol version number is followed by one or more pairs of parameter
    /// name and value strings. A zero byte is required as a terminator after
    /// the last name/value pair. Parameters can appear in any order. user is required,
    /// others are optional. Each parameter is specified as:
    var parameters: PostgreSQLParameters

    /// Creates a new `PostgreSQLStartupMessage`.
    init(protocolVersion: Int32, parameters: PostgreSQLParameters) {
        self.protocolVersion = protocolVersion
        self.parameters = parameters
    }

    /// See Encodable.encode
    func encode(to encoder: Encoder) throws {
        var single = encoder.singleValueContainer()
        try single.encode(protocolVersion)
        try single.encode(parameters)
    }
}
