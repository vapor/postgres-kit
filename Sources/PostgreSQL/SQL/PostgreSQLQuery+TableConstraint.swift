extension PostgreSQLQuery {
    public struct TableConstraint {
        public enum Constraint {
            case check(Key, noInherit: Bool)
            case unique(Unique)
            case primaryKey(PrimaryKey)
            #warning("exclude")
            case foreignKey(ForeignKey)
        }
        
        public struct Unique {
            public var columns: [String]
            public var indexParameters: IndexParameters?
            
            public init(columns: [String], indexParameters: IndexParameters? = nil) {
                self.columns = columns
                self.indexParameters = indexParameters
            }
        }
        
        public struct PrimaryKey {
            public var columns: [String]
            public var indexParameters: IndexParameters?
            
            public init(columns: [String], indexParameters: IndexParameters? = nil) {
                self.columns = columns
                self.indexParameters = indexParameters
            }
        }
        
        public struct ForeignKey {
            public var columns: [String]
            public var foreignTable: String
            public var foreignColumns: [String]
            public var onDelete: ForeignKeyAction?
            public var onUpdate: ForeignKeyAction?
            
            public init(columns: [String], foreignTable: String, foreignColumns: [String], onDelete: ForeignKeyAction? = nil, onUpdate: ForeignKeyAction? = nil) {
                self.columns = columns
                self.foreignTable = foreignTable
                self.foreignColumns = foreignColumns
                self.onDelete = onDelete
                self.onUpdate = onUpdate
            }
        }
        
        public var name: String?
        public var constraint: Constraint
        public init(_ constraint: Constraint, as name: String? = nil) {
            self.constraint = constraint
            self.name = name
        }
    }
    
    public struct IndexParameters { }
}

extension PostgreSQLSerializer {
    internal func serialize(_ constraint: PostgreSQLQuery.TableConstraint) -> String {
        if let name = constraint.name {
            return "CONSTRAINT " + escapeString(name) + " " + serialize(constraint.constraint)
        } else {
            return serialize(constraint.constraint)
        }
    }
    
    internal func serialize(_ constraintType: PostgreSQLQuery.TableConstraint.Constraint) -> String {
        switch constraintType {
        case .unique(let unique): return serialize(unique)
        case .primaryKey(let primaryKey): return serialize(primaryKey)
        case .foreignKey(let foreignKey): return serialize(foreignKey)
        case .check: return "<UNIMPLEMENTED>"
        }
    }
        
    internal func serialize(_ foreignKey: PostgreSQLQuery.TableConstraint.ForeignKey) -> String {
        var sql: [String] = []
        sql.append("FOREIGN KEY")
        sql.append(group(foreignKey.columns.map(escapeString)))
        sql.append("REFERENCES")
        sql.append(escapeString(foreignKey.foreignTable))
        sql.append(group(foreignKey.foreignColumns.map(escapeString)))
        if let onDelete = foreignKey.onDelete {
            sql.append("ON DELETE")
            sql.append(serialize(onDelete))
        }
        if let onUpdate = foreignKey.onUpdate {
            sql.append("ON UPDATE")
            sql.append(serialize(onUpdate))
        }
        return sql.joined(separator: " ")
    }
    
    internal func serialize(_ foreignKey: PostgreSQLQuery.TableConstraint.Unique) -> String {
        var sql: [String] = []
        sql.append("UNIQUE")
        sql.append(group(foreignKey.columns.map(escapeString)))
        return sql.joined(separator: " ")
    }
    
    internal func serialize(_ foreignKey: PostgreSQLQuery.TableConstraint.PrimaryKey) -> String {
        var sql: [String] = []
        sql.append("PRIMARY KEY")
        sql.append(group(foreignKey.columns.map(escapeString)))
        return sql.joined(separator: " ")
    }
}
