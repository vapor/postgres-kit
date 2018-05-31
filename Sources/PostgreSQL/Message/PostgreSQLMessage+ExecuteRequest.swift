/// Identifies the message as an Execute command.
struct PostgreSQLExecuteRequest: Encodable {
    /// The name of the destination portal (an empty string selects the unnamed portal).
    var portalName: String

    /// Maximum number of rows to return, if portal contains a query that
    /// returns rows (ignored otherwise). Zero denotes “no limit”.
    var maxRows: Int32
}
