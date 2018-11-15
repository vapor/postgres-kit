import SQLKit

public struct PostgresQuery: SQLQuery {
    public typealias ColumnConstraint = ColumnDefinition.ColumnConstraint
    public typealias IndexModifier = CreateIndex.Modifier
    public typealias ForeignKeyAction = ForeignKey.Action
    
    public static func alterTable(_ alterTable: AlterTable) -> PostgresQuery {
        return self.init(.alterTable(alterTable))
    }
    
    public static func createIndex(_ createIndex: CreateIndex) -> PostgresQuery {
        return self.init(.createIndex(createIndex))
    }
    
    public static func createTable(_ createTable: CreateTable) -> PostgresQuery {
        return self.init(.createTable(createTable))
    }
    
    public static func delete(_ delete: Delete) -> PostgresQuery {
        return self.init(.delete(delete))
    }
    
    public static func dropIndex(_ dropIndex: DropIndex) -> PostgresQuery {
        return self.init(.dropIndex(dropIndex))
    }
    
    public static func dropTable(_ dropTable: DropTable) -> PostgresQuery {
        return self.init(.dropTable(dropTable))
    }
    
    public static func insert(_ insert: Insert) -> PostgresQuery {
        return self.init(.insert(insert))
    }
    
    public static func select(_ select: Select) -> PostgresQuery {
        return self.init(.select(select))
    }
    
    public static func update(_ update: Update) -> PostgresQuery {
        return self.init(.update(update))
    }
    
    public static func raw(_ sql: String, binds: [Encodable]) -> PostgresQuery {
        return self.init(.raw(sql, binds))
    }
    
    
    enum Storage {
        case alterTable(AlterTable)
        case createIndex(CreateIndex)
        case createTable(CreateTable)
        case delete(Delete)
        case dropIndex(DropIndex)
        case dropTable(DropTable)
        case insert(Insert)
        case select(Select)
        case update(Update)
        case raw(String, [Encodable])
    }
    
    let storage: Storage
    
    init(_ storage: Storage) {
        self.storage = storage
    }
    
    public func serialize(_ binds: inout [Encodable]) -> String {
        switch self.storage {
        case .alterTable(let alterTable): return alterTable.serialize(&binds)
        case .createIndex(let createIndex): return createIndex.serialize(&binds)
        case .createTable(let createTable): return createTable.serialize(&binds)
        case .delete(let delete): return delete.serialize(&binds)
        case .dropIndex(let dropIndex): return dropIndex.serialize(&binds)
        case .dropTable(let dropTable): return dropTable.serialize(&binds)
        case .insert(let insert): return insert.serialize(&binds)
        case .select(let select): return select.serialize(&binds)
        case .update(let update): return update.serialize(&binds)
        case .raw(let sql, let values):
            binds = values
            return sql
        }
    }
}
