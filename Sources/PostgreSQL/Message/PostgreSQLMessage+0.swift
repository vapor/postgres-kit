// note: Please list enum cases alphabetically.

/// A frontend or backend PostgreSQL message.
enum PostgreSQLMessage {    
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
    case close(CloseResponse)
    
    /// Identifies the message as a data row.
    case dataRow(DataRow)
    
    /// Identifies the message as a Describe command.
    case describe(DescribeRequest)
    
    /// Identifies the message as an error.
    case error(ErrorResponse)
    
    /// Identifies the message as an Execute command.
    case execute(ExecuteRequest)
    
    /// Identifies the message as a no-data indicator.
    case noData
    
    /// Identifies the message as a notice.
    case notice(ErrorResponse)
    
    /// Identifies the message as a notification response.
    case notification(Notification)
    
    /// Identifies the message as a parameter description.
    case parameterDescription(ParameterDescription)
    
    /// Identifies the message as a run-time parameter status report.
    case parameterStatus(ParameterStatus)
    
    /// Identifies the message as a Parse command.
    case parse(ParseRequest)
    
    /// Identifies the message as a Parse-complete indicator.
    case parseComplete
    
    /// Identifies the message as a password response.
    case password(PasswordMessage)
    
    /// Identifies the message as a simple query.
    case query(Query)
    
    /// Identifies the message type. ReadyForQuery is sent whenever the backend is ready for a new query cycle.
    case readyForQuery(ReadyForQuery)
    
    /// Identifies the message as a row description.
    case rowDescription(RowDescription)
    
    /// Response after sending an sslSupportRequest message.
    case sslSupportResponse(SupportResponse)
    
    /// Asks the server if it supports SSL.
    case sslSupportRequest(SSLSupportRequest)
    
    /// Startup message
    case startupMessage(StartupMessage)
    
    /// Identifies the message as a Sync command.
    case sync
}
