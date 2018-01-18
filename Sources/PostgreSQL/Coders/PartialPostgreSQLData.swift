/// Reference wrapper for `PostgreSQLData` being mutated
/// by the PostgreSQL data coders.
final class PartialPostgreSQLData {
    /// The partial data.
    var data: PostgreSQLData

    /// Creates a new `PartialPostgreSQLData`.
    init(data: PostgreSQLData) {
        self.data = data
    }

    /// Sets the `PostgreSQLData` at supplied coding path.
    func set(_ data: PostgreSQLData, at path: [CodingKey]) throws {
        fatalError()
    }
}
