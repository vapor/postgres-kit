/// First message sent from the frontend during startup.
struct PostgreSQLErrorResponse: Decodable, Error {
    /// The error messages.
    var strings: [String]

    /// Creates a new `PostgreSQLErrorResponse`.
    init(strings: [String]) {
        self.strings = strings
    }

    /// See Decodable.init
    init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        var strings: [String] = []
        parse: while true {
            let byte = try single.decode(UInt8.self)
            switch byte {
            case 0: break parse
            default:
                let string = try single.decode(String.self)
                strings.append(string)
            }
        }
        self.init(strings: strings)
    }
}
