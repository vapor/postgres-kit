import SQLKit

extension PostgresQuery {
    public struct ForeignKey: SQLForeignKey {
        public typealias Identifier = PostgresQuery.Identifier
        public typealias ForeignKeyAction = Action
        
        public static func foreignKey(
            table: Identifier,
            columns: [Identifier],
            onDelete: Action?,
            onUpdate: Action?
        ) -> ForeignKey {
            return self.init(table: table, columns: columns, onDelete: onDelete, onUpdate: onUpdate)
        }
        
        private let table: Identifier
        private let columns: [Identifier]
        private let onDelete: Action?
        private let onUpdate: Action?
        
        public func serialize(_ binds: inout [Encodable]) -> String {
            var sql: [String] = []
            sql.append(self.table.serialize(&binds))
            sql.append("(" + self.columns.serialize(&binds) + ")")
            if let onDelete = self.onDelete {
                sql.append("ON DELETE")
                sql.append(onDelete.serialize(&binds))
            }
            if let onUpdate = self.onUpdate {
                sql.append("ON UPDATE")
                sql.append(onUpdate.serialize(&binds))
            }
            return sql.joined(separator: " ")
        }
        
        
    }
}

extension PostgresQuery.ForeignKey {
    public struct Action: SQLForeignKeyAction {
        public static var noAction: PostgresQuery.ForeignKey.Action {
            return self.init(.noAction)
        }
        
        public static var restrict: PostgresQuery.ForeignKey.Action {
            return self.init(.restrict)
        }
        
        public static var cascade: PostgresQuery.ForeignKey.Action {
            return self.init(.cascade)
        }
        
        public static var setNull: PostgresQuery.ForeignKey.Action {
            return self.init(.setNull)
        }
        
        public static var setDefault: PostgresQuery.ForeignKey.Action {
            return self.init(.setDefault)
        }
        
        private enum Storage {
            case noAction
            case restrict
            case cascade
            case setNull
            case setDefault
        }
        
        private let storage: Storage
        
        private init(_ storage: Storage) {
            self.storage = storage
        }
        
        public func serialize(_ binds: inout [Encodable]) -> String {
            
            switch self.storage {
            case .noAction: return "NO ACTION"
            case .restrict: return "RESTRICT"
            case .cascade: return "CASCADE"
            case .setNull: return "SET NULL"
            case .setDefault: return "SET DEFAULT"
            }
        }
    }
}
