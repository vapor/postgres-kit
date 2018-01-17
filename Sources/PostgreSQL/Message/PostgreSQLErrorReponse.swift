import Bits

/// First message sent from the frontend during startup.
struct PostgreSQLDiagnosticResponse: Decodable, Error {
    /// The diagnostic messages.
    var fields: [PostgreSQLDiagnosticField]

    /// See Decodable.init
    init(from decoder: Decoder) throws {
        fields = []
        let single = try decoder.singleValueContainer()
        parse: while true {
            let field = try single.decode(PostgreSQLDiagnosticField.self)
            guard field.type != 0 else {
                break parse
            }
            fields.append(field)
        }
    }
}

struct PostgreSQLDiagnosticField: Decodable {
    /// Diagnostic type
    var type: Byte

    /// The message
    var message: String

    /// See Decodable.init
    init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        let byte = try single.decode(UInt8.self)
        type = byte
        switch byte {
        case 0: message = ""
        default: message = try single.decode(String.self)
        }
    }
}
