extension PostgresRow {
    public func sql(decoder: PostgresDataDecoder = .init()) -> SQLRow {
        return _PostgresSQLRow(row: self.makeRandomAccess(), decoder: decoder)
    }
}

// MARK: Private

private struct _PostgresSQLRow: SQLRow {
    let randomAccessView: PostgresRandomAccessRow
    let decoder: PostgresDataDecoder

    enum _Error: Error {
        case missingColumn(String)
    }
    
    init(row: PostgresRandomAccessRow, decoder: PostgresDataDecoder) {
        self.randomAccessView = row
        self.decoder = decoder
    }

    var allColumns: [String] {
        self.randomAccessView.map { $0.columnName }
    }

    func contains(column: String) -> Bool {
        self.randomAccessView.contains(column)
    }

    func decodeNil(column: String) throws -> Bool {
        !self.randomAccessView.contains(column) || self.randomAccessView[column].bytes == nil
    }

    func decode<D>(column: String, as type: D.Type) throws -> D where D : Decodable {
        guard self.randomAccessView.contains(column) else {
            throw _Error.missingColumn(column)
        }
        return try self.decoder.decode(D.self, from: self.randomAccessView[data: column])
    }
}
