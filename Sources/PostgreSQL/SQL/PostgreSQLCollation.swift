public struct PostgreSQLCollation: SQLCollation {
    public func serialize(_ binds: inout [Encodable]) -> String {
        return "COLLATE"
    }
}
