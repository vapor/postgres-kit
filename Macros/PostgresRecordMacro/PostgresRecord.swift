import PostgresNIO

public protocol PostgresRecord {
    init(
        _from row: PostgresRow,
        context: PostgresDecodingContext<some PostgresJSONDecoder>,
        file: String,
        line: Int
    ) throws
}
