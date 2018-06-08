public protocol PostgreSQLTable: Codable, Reflectable {
    static var postgreSQLTable: String { get }
}

extension PostgreSQLTable {
    /// See `PostgreSQLTable`.
    public static var postgreSQLTable: String {
        return "\(Self.self)"
    }
}


extension KeyPath where Root: PostgreSQLTable {
    public var column: PostgreSQLQuery.Column {
        guard let property = try! Root.reflectProperty(forKey: self) else {
            fatalError("Could not reflect key of type \(Value.self) for \(Root.self): \(self)")
        }
        return .init(table: Root.postgreSQLTable, name: property.path[0])
    }
}
