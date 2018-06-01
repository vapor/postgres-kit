/// Represents a PostgreSQL column.
public struct PostgreSQLColumn: Hashable, Equatable {
    /// The table this column belongs to.
    public var tableOID: UInt32
    
    /// The column's name.
    public var name: String
}

extension PostgreSQLColumn: CustomStringConvertible {
    /// See `CustomStringConvertible`.
    public var description: String {
        switch tableOID {
        case 0: return tableOID.description + "." + name
        default: return name
        }
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
    public func value(forTableOID tableOID: UInt32, atColumn column: String) -> Value? {
        return self[PostgreSQLColumn(tableOID: tableOID, name: column)]
    }
}
