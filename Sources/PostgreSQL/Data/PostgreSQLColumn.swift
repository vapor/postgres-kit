/// Represents a PostgreSQL column.
public struct PostgreSQLColumn: Hashable {
    /// See `Hashable.hashValue`
    public var hashValue: Int {
        return ((table ?? "_") + "." + name).hashValue
    }
    
    /// The table this column belongs to.
    public var table: String?

    /// The column's name.
    public var name: String
}

extension PostgreSQLColumn: CustomStringConvertible {
    public var description: String {
        if let table = table {
            return "\(table)(\(name))"
        } else {
            return "\(name)"
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
    public func value(forTable table: String, atColumn column: String) -> Value? {
        return self[PostgreSQLColumn(table: table, name: column)]
    }
}

import Async

final class PostgreSQLTableNameCache {
    var connection: Future<PostgreSQLConnection>
    var cache: [Int32: String?]
    var working: Bool

    init(connection: Future<PostgreSQLConnection>) {
        self.connection = connection
        self.cache = [:]
        self.working = false
    }

    func tableName(oid: Int32) throws -> String? {
        if oid == 0 {
            return nil
        }

        if working {
            cache[oid] = "pg_class"
            return "pg_class"
        }
        working = true
        defer { working = false }
        if let existing = cache[oid] {
            return existing
        } else {
            let res = try connection
                .wait()
                .simpleQuery("select relname from pg_class where oid = \(oid)")
                .wait()
            let new: String?
            if res.count > 0 {
                new = try res[0].firstValue(forColumn: "relname")!.decode(String.self)
            } else {
                new = nil
            }
            cache[oid] = new
            return new
        }
    }
}
