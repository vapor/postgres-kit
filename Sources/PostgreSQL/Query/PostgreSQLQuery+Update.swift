extension PostgreSQLQuery {
    /// If ONLY is specified before the table name, matching rows are updated in the named table only.
    /// If ONLY is not specified, matching rows are also updated in any tables inheriting from the named table.
    /// Optionally, * can be specified after the table name to explicitly indicate that descendant tables are included.
    public enum UpdateLocality {
        case selfOnly
        case inherited
    }
    
//    public static func update(
//        locality: UpdateLocality = .inherited,
//        table: TableName,
//        values: [String: Value],
//        where predicate: Predicate? = nil,
//        returning keys: Key...
//    ) -> PostgreSQLQuery {
//        return .update(.init(locality: locality, table: table, values: values, predicate: predicate, returning: keys))
//    }
    
    /// `UPDATE` queries.
    ///
    ///     [ WITH [ RECURSIVE ] with_query [, ...] ]
    ///     UPDATE [ ONLY ] table_name [ * ] [ [ AS ] alias ]
    ///         SET { column_name = { expression | DEFAULT } |
    ///               ( column_name [, ...] ) = [ ROW ] ( { expression | DEFAULT } [, ...] ) |
    ///               ( column_name [, ...] ) = ( sub-SELECT )
    ///             } [, ...]
    ///         [ FROM from_list ]
    ///         [ WHERE condition | WHERE CURRENT OF cursor_name ]
    ///         [ RETURNING * | output_expression [ [ AS ] output_name ] [, ...] ]
    ///
    /// https://www.postgresql.org/docs/10/static/sql-update.html
    public struct Update {
        /// See `UpdateLocality`.
        public var locality: UpdateLocality
        
        /// The name (optionally schema-qualified) of the table to update.
        public var table: TableName
        
        /// Values to update.
        public var values: [String: Value]
        
        /// UPDATE changes the values of the specified columns in all rows that satisfy the condition.
        public var predicate: Predicate?
        
        /// The optional RETURNING clause causes UPDATE to compute and return value(s) based on each row actually updated.
        /// Any expression using the table's columns, and/or columns of other tables mentioned in FROM, can be computed.
        /// The new (post-update) values of the table's columns are used.
        /// The syntax of the RETURNING list is identical to that of the output list of SELECT.
        public var returning: [Key]
        
        /// Creates a new `Update`.
        public init(locality: UpdateLocality = .inherited, table: TableName, values: [String: Value] = [:], predicate: Predicate? = nil, returning: [Key] = []) {
            self.locality = locality
            self.table = table
            self.values = values
            self.predicate = predicate
            self.returning = returning
        }
    }
}

extension PostgreSQLSerializer {
    mutating func serialize(_ update: PostgreSQLQuery.Update, _ binds: inout [PostgreSQLData]) -> String {
        var sql: [String] = []
        sql.append("UPDATE")
        switch update.locality {
        case .inherited: break
        case .selfOnly: sql.append("ONLY")
        }
        sql.append(serialize(update.table))
        sql.append("SET")
        sql.append(update.values.map { serialize($0.key, $0.value, &binds) }.joined(separator: ", "))
        if let predicate = update.predicate {
            sql.append("WHERE")
            sql.append(serialize(predicate, &binds))
        }
        if !update.returning.isEmpty {
            sql.append("RETURNING")
            sql.append(update.returning.map(serialize).joined(separator: ", "))
        }
        return sql.joined(separator: " ")
    }
    
    private mutating func serialize(_ col: String, _ val: PostgreSQLQuery.Value, _ binds: inout [PostgreSQLData]) -> String {
        return escapeString(col) + " = " + serialize(val, &binds)
    }
}
