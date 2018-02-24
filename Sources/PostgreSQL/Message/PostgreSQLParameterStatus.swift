struct PostgreSQLParameterStatus: Decodable {
    /// The name of the run-time parameter being reported.
    var parameter: String
    
    /// The current value of the parameter.
    var value: String
}

extension PostgreSQLParameterStatus: CustomStringConvertible {
    /// CustomStringConvertible.description
    var description: String {
        return "\(parameter): \(value)"
    }
}
