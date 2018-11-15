import SQLKit

extension PostgresQuery {
    #warning("implement me")
    public struct Collation: SQLCollation {
        public func serialize(_ binds: inout [Encodable]) -> String {
            return "COLLATE"
        }
    }
}

