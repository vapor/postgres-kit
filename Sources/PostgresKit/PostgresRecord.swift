import PostgresRecordMacro
import PostgresNIO

/// Enables the type to be easily and performantly decoded from the a `PostgresRow`:
/// ```swift
/// @PostgresRecord
/// struct MyTable {
///     let one: Int
///     let two: String
/// }
/// let rows: [PostgresRow] = dbManager.sql(...)
/// let items: [MyTable] = try rows.map { row in
///     try row.decode(MyTable.self)
/// }
/// ```
///
/// WARNING:
/// The returned postgres row data must be in the same order as declared in the Swift type.
/// So basically make sure the order of the retrieved columns is the same order as the variables of the type.
@attached(
    extension,
    conformances: PostgresRecord,
    names: named(init)
)
public macro PostgresRecord() = #externalMacro(
    module: "PostgresRecordMacro",
    type: "PostgresRecordMacroType"
)

// MARK: PostgresRecord
public protocol PostgresRecord {
    init(
        _from row: PostgresRow,
        context: PostgresDecodingContext<some PostgresJSONDecoder>,
        file: String,
        line: Int
    ) throws
}

// MARK: +PostgresRow
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

#warning("to test")
@PostgresRecord
struct MyTable {
    let thing: String
}
