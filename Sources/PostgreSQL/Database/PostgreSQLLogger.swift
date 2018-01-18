/// Capable of logging PostgreSQL queries.
public protocol PostgreSQLLogger {
    /// Logs the query and supplied parameters.
    func log(query: String, parameters: [PostgreSQLData])
}
