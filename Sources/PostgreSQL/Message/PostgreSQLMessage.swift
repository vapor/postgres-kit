import Bits

/// A frontend or backend PostgreSQL message.
enum PostgreSQLMessage {
    case startupMessage(PostgreSQLStartupMessage)
    /// Identifies the message as an error.
    case error(PostgreSQLDiagnosticResponse)
    /// Identifies the message as a notice.
    case notice(PostgreSQLDiagnosticResponse)
    case authenticationRequest(PostgreSQLAuthenticationRequest)
    case parameterStatus(PostgreSQLParameterStatus)
    case backendKeyData(PostgreSQLBackendKeyData)
    case readyForQuery(PostgreSQLReadyForQuery)
    case query(PostgreSQLQuery)
    case rowDescription(PostgreSQLRowDescription)
    case dataRow(PostgreSQLDataRow)
    case close(PostgreSQLCloseCommand)
    case parse(PostgreSQLParseRequest)
    /// Identifies the message as a parameter description.
    case parameterDescription(PostgreSQLParameterDescription)
    /// Identifies the message as a Bind command.
    case bind(PostgreSQLBindRequest)
    /// Identifies the message as a Describe command.
    case describe(PostgreSQLDescribeRequest)
    /// Identifies the message as an Execute command.
    case execute(PostgreSQLExecuteRequest)
    /// Identifies the message as a Sync command.
    case sync
    /// Identifies the message as a Parse-complete indicator.
    case parseComplete
    /// Identifies the message as a Bind-complete indicator.
    case bindComplete
    /// Identifies the message as a no-data indicator.
    case noData
}
