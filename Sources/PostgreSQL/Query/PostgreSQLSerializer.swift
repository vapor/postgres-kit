extension PostgreSQLQuery {
    public func serialize(_ binds: inout [PostgreSQLData]) -> String {
        var serializer = PostgreSQLSerializer()
        return serializer.serialize(self, &binds)
    }
}
    
internal struct PostgreSQLSerializer {
    var placeholderOffset: Int
    init() {
        self.placeholderOffset = 1
    }
    
    internal func group(_ strings: [String]) -> String {
        return "(" + strings.joined(separator: ", ") + ")"
    }
    
    internal func escapeString(_ string: String) -> String {
        return "\"" + string + "\""
    }
    
    internal func stringLiteral(_ string: String) -> String {
        return "'" + string + "'"
    }
    
    internal mutating func nextPlaceholder() -> String {
        defer { placeholderOffset += 1 }
        return "$" + placeholderOffset.description
    }
}
