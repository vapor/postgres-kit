struct PostgreSQLParameterStatus: Decodable {
    /// The name of the run-time parameter being reported.
    var parameter: String
    /// The current value of the parameter.
    var value: String

    /// See Decodable.decode
    init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        self.parameter = try single.decode(String.self)
        self.value = try single.decode(String.self)
    }
}

extension PostgreSQLParameterStatus: CustomStringConvertible {
    /// CustomStringConvertible.description
    var description: String {
        return "\(parameter): \(value)"
    }
}
