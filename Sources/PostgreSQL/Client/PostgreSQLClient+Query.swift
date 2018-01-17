import Async

extension PostgreSQLClient {
    /// Sends a simple PostgreSQL query command, collecting the parsed results.
    public func query(_ string: String) -> Future<[[String: PostgreSQLData]]> {
        var rows: [[String: PostgreSQLData]] = []
        return query(string) { row in
            rows.append(row)
            }.map(to: [[String: PostgreSQLData]].self) {
                return rows
        }
    }

    /// Sends a simple PostgreSQL query command, returning the parsed results to
    /// the supplied closure.
    public func query(_ string: String, onRow: @escaping ([String: PostgreSQLData]) -> ()) -> Future<Void> {
        var currentRow: PostgreSQLRowDescription?
        let query = PostgreSQLQuery(query: string)
        return queueStream.enqueue([.query(query)]) { message in
            switch message {
            case .rowDescription(let row):
                currentRow = row
            case .dataRow(let data):
                let row = currentRow !! "Unexpected PostgreSQLDataRow without preceding PostgreSQLRowDescription."
                let parsed = try row.parse(data: data, formats: row.fields.map { $0.formatCode })
                onRow(parsed)
            case .close: break // query over, waiting for `readyForQuery`
            case .readyForQuery: return true
            case .errorResponse(let e): throw e
            default: fatalError("Unexpected message during PostgreSQLQuery: \(message)")
            }
            return false // more messages, please
        }
    }
}
