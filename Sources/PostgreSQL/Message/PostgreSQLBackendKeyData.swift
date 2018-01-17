/// Identifies the message as cancellation key data.
/// The frontend must save these values if it wishes to be able to
/// issue CancelRequest messages later.
struct PostgreSQLBackendKeyData: Decodable {
    /// The process ID of this backend.
    var processID: Int32
    
    /// The secret key of this backend.
    var secretKey: Int32
}

extension PostgreSQLBackendKeyData: CustomStringConvertible {
    /// CustomStringConvertible.description
    var description: String {
        return "processID: \(processID), secretKey: \(secretKey)"
    }
}
