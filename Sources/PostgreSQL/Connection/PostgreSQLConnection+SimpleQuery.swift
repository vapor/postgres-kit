extension PostgreSQLConnection {
    public func simpleQuery<D>(_ query: PostgreSQLQuery, decoding: D.Type) -> Future<[D]> where D: Decodable {
        return simpleQuery(query).map { rows in
            return try rows.map { row in
                return try PostgreSQLRowDecoder().decode(D.self, from: row)
            }
        }
    }
    
    public func simpleQuery(_ query: PostgreSQLQuery) -> Future<[[PostgreSQLColumn: PostgreSQLData]]> {
        var rows: [[PostgreSQLColumn: PostgreSQLData]] = []
        return simpleQuery(query) { row in
            rows.append(row)
        }.map(to: [[PostgreSQLColumn: PostgreSQLData]].self) {
            return rows
        }
    }
    
    public func simpleQuery<D>(_ query: PostgreSQLQuery, decoding: D.Type, onRow: @escaping (D) throws -> ()) -> Future<Void> where D: Decodable {
        return simpleQuery(query) { row in
            try onRow(PostgreSQLRowDecoder().decode(D.self, from: row))
        }
    }
    
    public func simpleQuery(_ query: PostgreSQLQuery, onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) throws -> ()) -> Future<Void> {
        var binds: [PostgreSQLData] = []
        let sql = query.serialize(binds: &binds)
        assert(binds.count == 0, "Binds not allowed in simpleQuery(...). Use query(...) instead.")
        return operation { self._simpleQuery(sql, onRow: onRow) }
    }
    
    // MARK: Private

    /// Non-operation bounded simple query.
    private func _simpleQuery(_ string: String, onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) throws -> ()) -> Future<Void> {
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
