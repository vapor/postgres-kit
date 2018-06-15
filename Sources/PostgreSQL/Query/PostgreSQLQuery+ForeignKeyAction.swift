extension PostgreSQLQuery {
    /// In addition, when the data in the referenced columns is changed, certain actions are performed on the data in this table's
    /// columns. The ON DELETE clause specifies the action to perform when a referenced row in the referenced table is being deleted.
    /// Likewise, the ON UPDATE clause specifies the action to perform when a referenced column in the referenced table is being updated
    /// to a new value. If the row is updated, but the referenced column is not actually changed, no action is done. Referential actions
    /// other than the NO ACTION check cannot be deferred, even if the constraint is declared deferrable. There are the following possible
    /// actions for each clause.
    ///
    /// https://www.postgresql.org/docs/10/static/sql-createtable.html.
    public enum ForeignKeyAction {
        /// Produce an error indicating that the deletion or update would create a foreign key constraint violation.
        /// If the constraint is deferred, this error will be produced at constraint check time if there still exist
        /// any referencing rows. This is the default action.
        case noAction
        /// Produce an error indicating that the deletion or update would create a foreign key constraint violation.
        /// This is the same as NO ACTION except that the check is not deferrable.
        case restrict
        /// Delete any rows referencing the deleted row, or update the values of the referencing column(s) to the new
        // values of the referenced columns, respectively.
        case cascade
        /// Set the referencing column(s) to null.
        case setNull
        /// Set the referencing column(s) to their default values. (There must be a row in the referenced table matching
        /// the default values, if they are not null, or the operation will fail.)
        case setDefault
    }
}

extension PostgreSQLSerializer {
    internal func serialize(_ action: PostgreSQLQuery.ForeignKeyAction) -> String {
        switch action {
        case .noAction: return "NO ACTION"
        case .restrict: return "RESTRICT"
        case .cascade: return "CASCADE"
        case .setNull: return "SET NULL"
        case .setDefault: return "SET DEFAULT"
        }
    }
}
