private struct PGClass: PostgreSQLTable {
    static let sqlTableIdentifierString = "pg_class"
    var oid: UInt32
    var relname: String
}

extension PostgreSQLConnection {
    /// Caches table OID to string name associations.
    public struct TableNameCache {
        /// Stores table names. [OID: Name]
        private let tableNames: [UInt32: String]
        /// Stores table OIDs. [Name: OID]
        /// Used to accelerate the Name -> OID lookup.
        private let tableOIDs: [String: UInt32]
        
        /// Fetches the table name for a given table OID. Returns `nil` if no table with that OID is known.
        ///
        /// - parameters:
        ///     - oid: Table OID.
        /// - returns: Table name.
        public func tableName(oid: UInt32) -> String? {
            return tableNames[oid]
        }
        
        /// Fetches the table OID for a given table name. Returns `nil` if no table with that name is known.
        ///
        /// - parameters:
        ///     - name: Table name.
        /// - returns: Table OID.
        public func tableOID(name: String) -> UInt32? {
            return tableOIDs[name]
        }
        
        /// Creates a new cache.
        fileprivate init(_ tableClasses: [PGClass]) {
            var tableNames: [UInt32: String] = [:]
            var tableOIDs: [String: UInt32] = [:]
            for tableClass in tableClasses {
                tableNames[tableClass.oid] = tableClass.relname
                tableOIDs[tableClass.relname] = tableClass.oid
            }
            self.tableNames = tableNames
            self.tableOIDs = tableOIDs
        }
    }

    /// Fetches a struct that can convert table OIDs to table names.
    ///
    ///     SELECT oid, relname FROM pg_class
    ///
    /// The table names will be cached on the connection after fetching.
    public func tableNames(refresh: Bool = false) -> Future<TableNameCache> {
        if let existing = tableNameCache, !refresh {
            return future(existing)
        } else {
            return select().column("oid").column("relname").from(PGClass.self).all().map { rows in
                let rows = try rows.map { try self.decode(PGClass.self, from: $0, table: nil) }
                let new = TableNameCache(rows)
                self.tableNameCache = new
                return new
            }
        }
    }
}
