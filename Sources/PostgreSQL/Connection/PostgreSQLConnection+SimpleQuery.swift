extension PostgreSQLConnection {
    public func simpleQuery(_ q: Query<PostgreSQLDatabase>) -> Future<[[PostgreSQLColumn: PostgreSQLData]]> {
        var rows: [[PostgreSQLColumn: PostgreSQLData]] = []
        return query(q) { row in
            rows.append(row)
        }.map {
            return rows
        }
    }
    
    public func simpleQuery(_ q: Query<PostgreSQLDatabase>, onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) -> ()) -> Future<Void> {
        var binds = Binds()
        let sql = PostgreSQLSerializer().serialize(query: q, binds: &binds)
        do {
            guard binds.values.count == 0 else {
                throw PostgreSQLError(identifier: "simpleQuery", reason: "Cannot bind values using simpleQuery. Use query instead.")
            }
            return query(sql, onRow: onRow)
        } catch {
            return future(error: error)
        }
    }
    
    public func simpleQuery(_ string: String) -> Future<[[PostgreSQLColumn: PostgreSQLData]]> {
        var rows: [[PostgreSQLColumn: PostgreSQLData]] = []
        return simpleQuery(string) { row in
            rows.append(row)
        }.map(to: [[PostgreSQLColumn: PostgreSQLData]].self) {
            return rows
        }
    }
    
    public func simpleQuery(_ string: String, onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) -> ()) -> Future<Void> {
        return operation { self._simpleQuery(string, onRow: onRow) }
    }
    
    // MARK: Private

    /// Non-operation bounded simple query.
    private func _simpleQuery(_ string: String, onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) -> ()) -> Future<Void> {
        logger?.record(query: string)
        var currentRow: PostgreSQLRowDescription?
        let query = PostgreSQLQuery(query: string)
        return send([.query(query)]) { message in
            switch message {
            case .rowDescription(let row):
                currentRow = row
            case .dataRow(let data):
                guard let row = currentRow else {
                    throw PostgreSQLError(identifier: "simpleQuery", reason: "Unexpected PostgreSQLDataRow without preceding PostgreSQLRowDescription.")
                }
                let parsed = try row.parse(data: data, formatCodes: row.fields.map { $0.formatCode })
                onRow(parsed)
            case .close: break // query over, waiting for `readyForQuery`
            default: throw PostgreSQLError(identifier: "simpleQuery", reason: "Unexpected message during PostgreSQLQuery: \(message)")
            }
        }
    }
}
