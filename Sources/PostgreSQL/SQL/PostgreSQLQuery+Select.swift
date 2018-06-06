extension PostgreSQLQuery {
//    public static func select(
//        candidates: Select.Candidates = .all,
//        _ keys: Key...,
//        from tables: [TableName] = [],
//        joins: [Join] = [],
//        predicate: Predicate? = nil,
//        orderBy: [OrderBy] = [],
//        groupBy: [Key] = [],
//        limit: Int? = nil,
//        offset: Int? = nil
//    ) -> PostgreSQLQuery {
//        return .select(.init(
//            candidates: candidates,
//            keys: keys,
//            tables: tables,
//            joins: joins,
//            predicate: predicate,
//            orderBy: orderBy,
//            groupBy: groupBy,
//            limit: limit,
//            offset: offset
//        ))
//    }
//    
    public struct Select {
        public enum Candidates {
            /// All row candiates are available for selection.
            case all
            /// Only distinct row candidates are available for selection.
            case distinct(columns: [Column])
        }
        
        public var candidates: Candidates
        public var keys: [Key]
        public var tables: [TableName]
        public var joins: [Join]
        public var predicate: Predicate?
        
        
        /// List of columns to order by.
        public var orderBy: [OrderBy]
        
        public var groupBy: [Key]
        
        public var limit: Int?
        public var offset: Int?
        
        public init(
            candidates: Candidates = .all,
            keys: [Key] = [],
            tables: [TableName] = [],
            joins: [Join] = [],
            predicate: Predicate? = nil,
            orderBy: [OrderBy] = [],
            groupBy: [Key] = [],
            limit: Int? = nil,
            offset: Int? = nil
        ) {
            self.candidates = candidates
            self.keys = keys
            self.tables = tables
            self.joins = joins
            self.predicate = predicate
            self.orderBy = orderBy
            self.groupBy = groupBy
            self.limit = limit
            self.offset = offset
        }
    }
}

extension PostgreSQLSerializer {
    internal mutating func serialize(_ select: PostgreSQLQuery.Select, _ binds: inout [PostgreSQLData]) -> String {
        var sql: [String] = []
        sql.append("SELECT")
        switch select.candidates {
        case .all: break
        case .distinct(let columns):
            sql.append("DISTINCT")
            if !columns.isEmpty {
                sql.append("(" + columns.map(serialize).joined(separator: ",") + ")")
            }
        }
        let keys = select.keys.isEmpty ? [.all] : select.keys
        sql.append(keys.map(serialize).joined(separator: ", "))
        if !select.tables.isEmpty {
            sql.append("FROM")
            sql.append(select.tables.map(serialize).joined(separator: ", "))
        }
        if !select.joins.isEmpty {
            sql += select.joins.map { serialize($0, &binds) }
        }
        if let predicate = select.predicate {
            sql.append("WHERE")
            sql.append(serialize(predicate, &binds))
        }
        return sql.joined(separator: " ")
    }
}
