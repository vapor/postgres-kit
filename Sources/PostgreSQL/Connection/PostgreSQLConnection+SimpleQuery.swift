import Async

extension PostgreSQLConnection {
    /// Sends a simple PostgreSQL query command, collecting the parsed results.
    public func simpleQuery(_ string: String) -> Future<[[String: PostgreSQLData]]> {
        var rows: [[String: PostgreSQLData]] = []
        return simpleQuery(string) { row in
            rows.append(row)
        }.map(to: [[String: PostgreSQLData]].self) {
            return rows
        }
    }

    /// Sends a simple PostgreSQL query command, returning the parsed results to
    /// the supplied closure.
    public func simpleQuery(_ string: String, onRow: @escaping ([String: PostgreSQLData]) -> ()) -> Future<Void> {
        logger?.log(query: string, parameters: [])
        var currentRow: PostgreSQLRowDescription?
        let query = PostgreSQLQuery(query: string)
        return send([.query(query)]) { message in
            switch message {
            case .rowDescription(let row):
                currentRow = row
            case .dataRow(let data):
                let row = currentRow !! "Unexpected PostgreSQLDataRow without preceding PostgreSQLRowDescription."
                let parsed = try row.parse(data: data, formatCodes: row.fields.map { $0.formatCode })
                onRow(parsed)
            case .close: break // query over, waiting for `readyForQuery`
            default: fatalError("Unexpected message during PostgreSQLQuery: \(message)")
            }
        }
    }
}
