extension PostgresRow: SQLRow {
    public func decode<D>(column: String, as type: D.Type) throws -> D where D : Decodable {
        guard let data = self.column(column) else {
            fatalError()
        }
        return try self.decoder.decode(D.self, from: data)
    }
}
