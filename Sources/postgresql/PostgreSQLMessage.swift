import Bits

/// A frontend or backend PostgreSQL message.
protocol PostgreSQLMessage: Codable {
    /// The first byte of a message identifies the message type
    static var identifier: Byte? { get }
}

/// First message sent from the frontend during startup.
struct PostgreSQLStartupMessage: PostgreSQLMessage {
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

    /// Creates a `PostgreSQLStartupMessage` with "3.0" as the protocol version.
    static func versionThree(parameters: PostgreSQLParameters) -> PostgreSQLStartupMessage {
        return .init(protocolVersion: 196608, parameters: parameters)
    }

    /// See `PostgreSQLMessage.identifier`
    static let identifier: Byte? = nil
}

/// Represents [String: String] parameters encoded
/// as a list of strings separated by null terminators
/// and finished by a single null terminator.
struct PostgreSQLParameters: Codable, ExpressibleByDictionaryLiteral {
    /// The internal parameter storage.
    var storage: [String: String]

    /// See Encodable.encode
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        for (key, val) in storage {
            try container.encode(key)
            try container.encode(val)
        }
        try container.encode("")
    }

    /// See ExpressibleByDictionaryLiteral.init
    init(dictionaryLiteral elements: (String, String)...) {
        var storage = [String: String]()
        for (key, val) in elements {
            storage[key] = val
        }
        self.storage = storage
    }
}
