/// Identifies the message as a parameter description.
struct PostgreSQLParameterDescription: Decodable {
    /// Specifies the object ID of the parameter data type.
    var dataTypes: [PostgreSQLDataType]
}
