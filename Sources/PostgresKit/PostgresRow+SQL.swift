extension PostgresRow {
    public func sql(decoder: PostgresDataDecoder = .init()) -> SQLRow {
        return _PostgreSQLRow(row: self, decoder: decoder)
    }
}

// MARK: Private

private struct _PostgreSQLRow: SQLRow {
    let row: PostgresRow
    let decoder: PostgresDataDecoder

    enum _Error: Error {
        case missingColumn(String)
    }

    var allColumns: [String] {
        self.row.rowDescription.fields.map { $0.name }
    }

    func contains(column: String) -> Bool {
        self.row.rowDescription.fields
            .contains { $0.name == column }
    }

    func decodeNil(column: String) throws -> Bool {
        self.row.column(column)?.value == nil
    }

    func decode<D>(column: String, as type: D.Type) throws -> D where D : Decodable {
        guard let data = self.row.column(column) else {
            throw _Error.missingColumn(column)
        }
        return try self.decoder.decode(D.self, from: data)
    }
}
