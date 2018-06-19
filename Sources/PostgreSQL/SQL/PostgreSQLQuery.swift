public enum PostgreSQLQuery: SQLQuery {
    /// See `SQLQuery`.
    public typealias AlterTable = PostgreSQLAlterTable
    
    /// See `SQLQuery`.
    public typealias CreateTable = PostgreSQLCreateTable
    
    /// See `SQLQuery`.
    public typealias Delete = PostgreSQLDelete
    
    /// See `SQLQuery`.
    public typealias DropTable = PostgreSQLDropTable
    
    /// See `SQLQuery`.
    public typealias Insert = PostgreSQLInsert
    
    /// See `SQLQuery`.
    public typealias Select = PostgreSQLSelect
    
    /// See `SQLQuery`.
    public typealias Update = PostgreSQLUpdate
    
    /// See `SQLQuery`.
    public typealias RowDecoder = PostgreSQLRowDecoder
    
    /// See `SQLQuery`.
    public static func alterTable(_ alterTable: AlterTable) -> PostgreSQLQuery {
        return ._alterTable(alterTable)
    }
    
    /// See `SQLQuery`.
    public static func createTable(_ createTable: CreateTable) -> PostgreSQLQuery {
        return ._createTable(createTable)
    }
    
    /// See `SQLQuery`.
    public static func delete(_ delete: Delete) -> PostgreSQLQuery {
        return ._delete(delete)
    }
    
    /// See `SQLQuery`.
    public static func dropTable(_ dropTable: DropTable) -> PostgreSQLQuery {
        return ._dropTable(dropTable)
    }
    
    /// See `SQLQuery`.
    public static func insert(_ insert: Insert) -> PostgreSQLQuery {
        return ._insert(insert)
    }
    
    /// See `SQLQuery`.
    public static func select(_ select: Select) -> PostgreSQLQuery {
        return ._select(select)
    }
    
    /// See `SQLQuery`.
    public static func update(_ update: Update) -> PostgreSQLQuery {
        return ._update(update)
    }
    
    /// See `SQLQuery`.
    public static func raw(_ sql: String, binds: [Encodable]) -> PostgreSQLQuery {
        return ._raw(sql, binds)
    }
    
    /// See `SQLQuery`.
    case _alterTable(PostgreSQLAlterTable)
    
    /// See `SQLQuery`.
    case _createTable(PostgreSQLCreateTable)
    
    /// See `SQLQuery`.
    case _delete(PostgreSQLDelete)
    
    /// See `SQLQuery`.
    case _dropTable(PostgreSQLDropTable)
    
    /// See `SQLQuery`.
    case _insert(PostgreSQLInsert)
    
    /// See `SQLQuery`.
    case _select(Select)
    
    /// See `SQLQuery`.
    case _update(Update)
    
    /// See `SQLQuery`.
    case _raw(String, [Encodable])
    
    /// See `SQLSerializable`.
    public func serialize(_ binds: inout [Encodable]) -> String {
        switch self {
        case ._alterTable(let alterTable): return alterTable.serialize(&binds)
        case ._createTable(let createTable): return createTable.serialize(&binds)
        case ._delete(let delete): return delete.serialize(&binds)
        case ._dropTable(let dropTable): return dropTable.serialize(&binds)
        case ._insert(let insert): return insert.serialize(&binds)
        case ._select(let select): return select.serialize(&binds)
        case ._update(let update): return update.serialize(&binds)
        case ._raw(let sql, let values):
            binds = values
            return sql
        }
    }
}

extension PostgreSQLQuery: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = ._raw(value, [])
    }
}
