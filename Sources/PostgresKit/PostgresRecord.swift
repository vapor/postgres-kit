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

#warning("to test")
@PostgresRecord
struct MyTable {
    static let tableName = "my_table"

    let int: Int
    let string: String

//    func update<PI1, PI2>(
//        key: KeyPath<Self, PI1>,
//        to: PI1,
//        whereKey: KeyPath<Self, PI2>,
//        isEqualTo whereTo: KeyPath<Self, PI2>,
//        on connection: PostgresConnection,
//        logger: Logger
//    ) async throws where PI1: PostgresInterpolatable, PI2: PostgresInterpolatable {
//        try await connection.query("""
//            UPDATE \(unescaped: Self.tableName)
//            SET \(key) = \(to),
//            WHERE \(whereKey) = \(whereTo)
//            """,
//            logger: logger
//        )
//    }
}
