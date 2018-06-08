extension PostgreSQLQuery {
    public enum ForeignKeyAction {
        case nullify
    }
}

extension PostgreSQLSerializer {
    internal func serialize(_ action: PostgreSQLQuery.ForeignKeyAction) -> String {
        switch action {
        case .nullify: return "NULLIFY"
        }
    }
}
