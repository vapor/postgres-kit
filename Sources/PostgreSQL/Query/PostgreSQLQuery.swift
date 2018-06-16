public enum PostgreSQLQuery {
    case alterTable(AlterTable)
    case createTable(CreateTable)
    case delete(Delete)
    case dropTable(DropTable)
    case insert(Insert)
    case listen(channel: String)
    case notify(channel: String, message: String)
    case raw(query: String, binds: [PostgreSQLData])
    case select(Select)
    case unlisten(channel: String)
    case update(Update)
}

extension PostgreSQLSerializer {
    mutating func serialize(_ query: PostgreSQLQuery, _ binds: inout [PostgreSQLData]) -> String {
        switch query {
        case .alterTable(let alter): return serialize(alter)
        case .createTable(let create): return serialize(create)
        case .delete(let delete): return serialize(delete, &binds)
        case .dropTable(let drop): return serialize(drop)
        case .insert(let insert): return serialize(insert, &binds)
        case .select(let select): return serialize(select,  &binds)
        case .listen(let channel): return "LISTEN " + escapeString(channel)
        case .notify(let channel, let message): return "NOTIFY " + escapeString(channel) + ", " + stringLiteral(message)
        case .raw(let raw, let values):
            binds = values
            return raw
        case .unlisten(let channel): return "UNLISTEN " + escapeString(channel)
        case .update(let update): return serialize(update, &binds)
        }
    }
}
