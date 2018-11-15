import SQLKit

extension PostgresQuery {
    public struct ColumnDefinition: SQLColumnDefinition {
        public typealias ColumnIdentifier = PostgresQuery.ColumnIdentifier
        public typealias DataType = PostgresQuery.DataType
    
        let column: ColumnIdentifier
        let dataType: DataType
        let constraints: [ColumnConstraint]
        
        public static func columnDefinition(
            _ column: ColumnIdentifier,
            _ dataType: DataType,
            _ constraints: [ColumnConstraint]
        ) -> ColumnDefinition {
            return self.init(column: column, dataType: dataType, constraints: constraints)
        }
        
        public func serialize(_ binds: inout [Encodable]) -> String {
            var sql: [String] = []
            sql.append(self.column.serialize(&binds))
            sql.append(self.dataType.serialize(&binds))
            sql.append(self.constraints.serialize(&binds, joinedBy: " "))
            return sql.joined(separator: " ")
        }
    }
}

extension PostgresQuery.ColumnDefinition {
    public struct ColumnConstraint: SQLColumnConstraint {
        public typealias Identifier = PostgresQuery.Identifier
        public typealias ConstraintAlgorithm = PostgresQuery.ConstraintAlgorithm
        
        public static func constraint(algorithm: ConstraintAlgorithm, name: Identifier?) -> ColumnConstraint {
            return self.init(algorithm: algorithm, name: name)
        }
        
        private let algorithm: ConstraintAlgorithm
        private let name: Identifier?
        
        public func serialize(_ binds: inout [Encodable]) -> String {
            if let name = self.name {
                return "CONSTRAINT " + name.serialize(&binds) + " " + algorithm.serialize(&binds)
            } else {
                return algorithm.serialize(&binds)
            }
        }
        
    }
}
