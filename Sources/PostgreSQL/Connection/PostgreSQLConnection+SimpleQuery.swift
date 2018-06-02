extension PostgreSQLConnection {
    // MARK: Query
    
    public func simpleQuery<D>(_ query: SQLQuery, decoding: D.Type) -> Future<[D]> where D: Decodable {
        var binds = Binds()
        let string = PostgreSQLSerializer().serialize(query: query, binds: &binds)
        assert(binds.values.count == 0, "Cannot bind values to simpleQuery. Use `query(...)` instead.")
        return simpleQuery(string, decoding: D.self)
    }
    
    public func simpleQuery(_ query: SQLQuery) -> Future<[[PostgreSQLColumn: PostgreSQLData]]> {
        var binds = Binds()
        let string = PostgreSQLSerializer().serialize(query: query, binds: &binds)
        assert(binds.values.count == 0, "Cannot bind values to simpleQuery. Use `query(...)` instead.")
        return simpleQuery(string)
    }
    
    public func simpleQuery<D>(_ query: SQLQuery, decoding: D.Type, onRow: @escaping (D) throws -> ()) -> Future<Void> where D: Decodable {
        var binds = Binds()
        let string = PostgreSQLSerializer().serialize(query: query, binds: &binds)
        assert(binds.values.count == 0, "Cannot bind values to simpleQuery. Use `query(...)` instead.")
        return simpleQuery(string, decoding: D.self, onRow: onRow)
    }
    
    public func simpleQuery(_ query: SQLQuery, onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) throws -> ()) -> Future<Void> {
        var binds = Binds()
        let string = PostgreSQLSerializer().serialize(query: query, binds: &binds)
        assert(binds.values.count == 0, "Cannot bind values to simpleQuery. Use `query(...)` instead.")
        return simpleQuery(string, onRow: onRow)
    }
    
    // MARK: String
    
    public func simpleQuery<D>(_ string: String, decoding: D.Type) -> Future<[D]> where D: Decodable {
        return simpleQuery(string).map { rows in
            return try rows.map { row in
                return try PostgreSQLRowDecoder().decode(D.self, from: row)
            }
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
    
    public func simpleQuery<D>(_ string: String, decoding: D.Type, onRow: @escaping (D) throws -> ()) -> Future<Void> where D: Decodable {
        return simpleQuery(string) { row in
            try onRow(PostgreSQLRowDecoder().decode(D.self, from: row))
        }
    }
    
    public func simpleQuery(_ string: String, onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) throws -> ()) -> Future<Void> {
        return operation { self._simpleQuery(string, onRow: onRow) }
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
