/// Represents a PostgreSQL column.
public struct PostgreSQLColumn: Hashable, Equatable {
    /// The table this column belongs to.
    public var tableOID: Int32

    /// The column's name.
    public var name: String
}

extension PostgreSQLColumn: CustomStringConvertible {
    public var description: String {
        return "<\(tableOID)>.(\(name))"
    }
}

extension Dictionary where Key == PostgreSQLColumn {
    /// Accesses the _first_ value from this dictionary with a matching field name.
    public func firstValue(forColumn columnName: String) -> Value? {
        for (field, value) in self {
            if field.name == columnName {
                return value
            }
        }
        return nil
    }

    /// Access a `Value` from this dictionary keyed by `PostgreSQLColumn`s
    /// using a field (column) name and entity (table) name.
    public func value(forTableOID tableOID: Int32, atColumn column: String) -> Value? {
        return self[PostgreSQLColumn(tableOID: tableOID, name: column)]
    }
}
