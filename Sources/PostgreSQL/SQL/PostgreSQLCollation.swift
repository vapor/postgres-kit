/// PostgreSQL specific `SQLCollation`.
public struct PostgreSQLCollation: SQLCollation {
    /// See `SQLSerializable`.
    public func serialize(_ binds: inout [Encodable]) -> String {
        return "COLLATE"
    }
}
