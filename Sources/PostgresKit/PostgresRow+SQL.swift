extension PostgresRow {
    public func sql(using decoder: PostgresDataDecoder) -> SQLRow {
        return _PostgreSQLRow(row: self, decoder: decoder)
    }
}

private struct _PostgreSQLRow: SQLRow {
    let row: PostgresRow
    let decoder: PostgresDataDecoder

    func decode<D>(column: String, as type: D.Type) throws -> D where D : Decodable {
        guard let data = self.row.column(column) else {
            fatalError()
        }
        return try self.decoder.decode(D.self, from: data)
    }
}
