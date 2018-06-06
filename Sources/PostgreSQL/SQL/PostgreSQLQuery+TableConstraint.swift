extension PostgreSQLQuery {
    public struct TableConstraint {
        public enum Constraint {
            case check(Expression, noInherit: Bool)
            case unique(columns: [String], IndexParameters?)
            case primaryKey(column: String, IndexParameters?)
            #warning("exclude")
            case foreignKey(columns: [String], reftable: String, refcolumns: [String], onDelete: ForeignKeyAction?, onUpdate: ForeignKeyAction?)
        }
        
        public var name: String?
        public var type: Constraint
        public init(_ type: Constraint, as name: String? = nil) {
            self.type = type
            self.name = name
        }
    }
    
    public struct IndexParameters { }
}

extension PostgreSQLSerializer {
    internal func serialize(_ create: PostgreSQLQuery.TableConstraint) -> String {
        return "FOO"
    }
}
