import PostgresNIO

extension PostgresRow {
    public func decode<Record: PostgresRecord>(
        _ recordType: Record.Type = Record.self,
        file: String = #fileID,
        line: Int = #line
    ) throws -> Record {
        try Record.init(
            _from: self,
            context: .default,
            file: file,
            line: line
        )
    }

    public func decode<Record: PostgresRecord>(
        _ recordType: Record.Type = Record.self,
        context: PostgresDecodingContext<some PostgresJSONDecoder>,
        file: String = #fileID,
        line: Int = #line
    ) throws -> Record {
        try Record.init(
            _from: self,
            context: context,
            file: file,
            line: line
        )
    }
}
