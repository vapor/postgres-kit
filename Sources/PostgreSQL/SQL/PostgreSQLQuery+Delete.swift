extension PostgreSQLQuery {
    public static func delete(
        locality: UpdateLocality = .inherited,
        from table: TableName,
        where predicate: Predicate? = nil,
        returning keys: Key...
    ) -> PostgreSQLQuery {
        return .delete(.init(locality: locality, table: table, predicate: predicate, returning: keys))
    }
    
    /// `DELETE` query.
    ///
    ///     [ WITH [ RECURSIVE ] with_query [, ...] ]
    ///     DELETE FROM [ ONLY ] table_name [ * ] [ [ AS ] alias ]
    ///         [ USING using_list ]
    ///         [ WHERE condition | WHERE CURRENT OF cursor_name ]
    ///         [ RETURNING * | output_expression [ [ AS ] output_name ] [, ...] ]
    ///
    /// https://www.postgresql.org/docs/10/static/sql-delete.html
    public struct Delete {
        /// See `UpdateLocality`.
        public var locality: UpdateLocality
        
        /// The name (optionally schema-qualified) of the table to delete rows from.
        public var table: TableName
        
        #warning("Add USING to delete query.")
        
        /// DELETE deletes rows that satisfy the WHERE clause from the specified table.
        /// If the WHERE clause is absent, the effect is to delete all rows in the table.
        /// The result is a valid, but empty table.
        public var predicate: Predicate?
        
        /// The optional RETURNING clause causes DELETE to compute and return value(s) based on each row actually deleted.
        /// Any expression using the table's columns, and/or columns of other tables mentioned in USING, can be computed.
        /// The syntax of the RETURNING list is identical to that of the output list of SELECT.
        public var returning: [Key]
        
        /// Creates a new `Delete`.
        public init(locality: UpdateLocality = .inherited, table: TableName, predicate: Predicate? = nil, returning: [Key] = []) {
            self.locality = locality
            self.table = table
            self.predicate = predicate
            self.returning = returning
        }
    }
}

extension PostgreSQLSerializer {
    mutating func serialize(_ delete: PostgreSQLQuery.Delete, _ binds: inout [PostgreSQLData]) -> String {
        var sql: [String] = []
        sql.append("DELETE FROM")
        switch delete.locality {
        case .inherited: break
        case .selfOnly: sql.append("ONLY")
        }
        sql.append(serialize(delete.table))
        if let predicate = delete.predicate {
            sql.append("WHERE")
            sql.append(serialize(predicate, &binds))
        }
        if !delete.returning.isEmpty {
            sql.append("RETURNING")
            sql.append(delete.returning.map(serialize).joined(separator: ", "))
        }
        return sql.joined(separator: " ")
    }
}
