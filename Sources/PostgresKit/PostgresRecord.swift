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
    names: arbitrary // for now
)
public macro PostgresRecord() = #externalMacro(
    module: "PostgresRecordMacro",
    type: "PostgresRecordMacroType"
)

#warning("to test")
@PostgresRecord
struct MyTable {
    let int: Int
    let string = ""

    static let name = ""
}
