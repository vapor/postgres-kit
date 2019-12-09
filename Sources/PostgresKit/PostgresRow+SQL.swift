extension PostgresRow {
    public func sqlRow(using decoder: PostgresDecoder) -> SQLRow {
        return _PostgreSQLRow(row: self, decoder: decoder)
    }

    public func sqlRow(using decoder: JSONDecoder = JSONDecoder()) -> SQLRow {
        return _PostgreSQLRow(row: self, decoder: PostgresDataDecoder(jsonDecoder: decoder))
    }
}

private struct _PostgreSQLRow: SQLRow {
    let row: PostgresRow
    let decoder: PostgresDecoder

    func decode<D>(column: String, as type: D.Type) throws -> D where D : Decodable {
        guard let data = self.row.column(column) else {
            fatalError()
        }
        return try self.decoder.decode(D.self, from: data)
    }
}
