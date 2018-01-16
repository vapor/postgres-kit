import Bits

/// A frontend or backend PostgreSQL message.
enum PostgreSQLMessage {
    case startupMessage(PostgreSQLStartupMessage)
    case errorResponse(PostgreSQLErrorResponse)
    case authenticationRequest(PostgreSQLAuthenticationRequest)
    case parameterStatus(PostgreSQLParameterStatus)
    case backendKeyData(PostgreSQLBackendKeyData)
    case readyForQuery(PostgreSQLReadyForQuery)
    case query(PostgreSQLQuery)
    case rowDescription(PostgreSQLRowDescription)
    case dataRow(PostgreSQLDataRow)
    case close(PostgreSQLCloseCommand)
    case parse(PostgreSQLParseRequest)
    /// Identifies the message as a Sync command.
    case sync
    /// Identifies the message as a Parse-complete indicator.
    case parseComplete
    /// Identifies the message as a Bind command.
    case bind(PostgreSQLBindRequest)
}
