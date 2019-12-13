extension PostgresRow {
    public func sql(decoder: PostgresDataDecoder = .init()) -> SQLRow {
        return _PostgreSQLRow(row: self, decoder: decoder)
    }
}

private struct _PostgreSQLRow: SQLRow {
    let row: PostgresRow
    let decoder: PostgresDataDecoder

    enum _Error: Error {
        case missingColumn(String)
    }

    var columns: [String] {
        self.row.columns
    }

    func contains(column: String) -> Bool {
        self.row.contains(column: column)
    }

    func decodeNil(column: String) throws -> Bool {
        self.row.column(column) == nil
    }

    func decode<D>(column: String, as type: D.Type) throws -> D where D : Decodable {
        guard let data = self.row.column(column) else {
            throw _Error.missingColumn(column)
        }
        return try self.decoder.decode(D.self, from: data)
    }
}
