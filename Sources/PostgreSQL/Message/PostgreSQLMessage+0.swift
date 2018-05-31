// note: Please list enum cases alphabetically.

/// A frontend or backend PostgreSQL message.
enum PostgreSQLMessage {
    /// The format code being used for the field.
    /// Currently will be zero (text) or one (binary).
    /// In a RowDescription returned from the statement variant of Describe,
    /// the format code is not yet known and will always be zero.
    enum FormatCode: Int16, Codable {
        case text = 0
        case binary = 1
    }
    
    /// One of the various authentication request message formats.
    case authenticationRequest(AuthenticationRequest)
    
    /// Identifies the message as cancellation key data.
    /// The frontend must save these values if it wishes to be able to issue CancelRequest messages later.
    case backendKeyData(BackendKeyData)
    
    /// Identifies the message as a Bind command.
    case bind(BindRequest)
    
    /// Identifies the message as a Bind-complete indicator.
    case bindComplete
    
    /// Identifies the message as a command-completed response.
    case close(PostgreSQLCloseResponse)
    
    /// Identifies the message as a data row.
    case dataRow(PostgreSQLDataRow)
    
    /// Identifies the message as a Describe command.
    case describe(PostgreSQLDescribeRequest)
    
    /// Identifies the message as an error.
    case error(PostgreSQLDiagnosticResponse)
    
    /// Identifies the message as an Execute command.
    case execute(PostgreSQLExecuteRequest)
    
    /// Identifies the message as a no-data indicator.
    case noData
    
    /// Identifies the message as a notice.
    case notice(PostgreSQLDiagnosticResponse)
    
    /// Identifies the message as a notification response.
    case notificationResponse(PostgreSQLNotificationResponse)
    
    /// Identifies the message as a parameter description.
    case parameterDescription(PostgreSQLParameterDescription)
    
    /// Identifies the message as a run-time parameter status report.
    case parameterStatus(PostgreSQLParameterStatus)
    
    /// Identifies the message as a Parse command.
    case parse(PostgreSQLParseRequest)
    
    /// Identifies the message as a Parse-complete indicator.
    case parseComplete
    
    /// Identifies the message as a password response.
    case password(PostgreSQLPasswordMessage)
    
    /// Identifies the message as a simple query.
    case query(PostgreSQLQuery)
    
    /// Identifies the message type. ReadyForQuery is sent whenever the backend is ready for a new query cycle.
    case readyForQuery(PostgreSQLReadyForQuery)
    
    /// Identifies the message as a row description.
    case rowDescription(PostgreSQLRowDescription)
    
    /// Response after sending an sslSupportRequest message.
    case sslSupportResponse(PostgreSQLSSLSupportResponse)
    
    /// Asks the server if it supports SSL.
    case sslSupportRequest(PostgreSQLSSLSupportRequest)
    
    /// Startup message
    case startupMessage(PostgreSQLStartupMessage)
    
    /// Identifies the message as a Sync command.
    case sync
}
