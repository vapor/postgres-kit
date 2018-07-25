extension PostgreSQLConnection {
    /// Performs a non-parameterized (text protocol) query to PostgreSQL.
    public func simpleQuery(_ query: String) -> Future<Void> {
        return operation { self._simpleQuery(query) { _ in }}
    }
    
    /// Performs a non-parameterized (text protocol) query to PostgreSQL.
    public func simpleQuery(_ query: String, _ onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) throws -> ()) -> Future<Void> {
        return operation { self._simpleQuery(query, onRow) }
    }
    
    // MARK: Private

    /// Non-operation bounded simple query.
    private func _simpleQuery(_ string: String, _ onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) throws -> ()) -> Future<Void> {
        logger?.record(query: string)
        var currentRow: PostgreSQLMessage.RowDescription?
        return send([.query(.init(query: string))]) { message in
            switch message {
            case .rowDescription(let row):
                currentRow = row
            case .dataRow(let data):
                guard let row = currentRow else {
                    throw PostgreSQLError(identifier: "simpleQuery", reason: "Unexpected PostgreSQLDataRow without preceding PostgreSQLRowDescription.")
                }
                let parsed = try row.parse(data: data, formatCodes: row.fields.map { $0.formatCode })
                try onRow(parsed)
            case .close: break // query over, waiting for `readyForQuery`
            default: throw PostgreSQLError(identifier: "simpleQuery", reason: "Unexpected message during PostgreSQLQuery: \(message)")
            }
        }
    }
}
