import SQLKit

extension PostgresQuery {
    public struct TableConstraint: SQLTableConstraint {
        public typealias Identifier = PostgresQuery.Identifier
        public typealias ConstraintAlgorithm = PostgresQuery.ConstraintAlgorithm
        
        public static func constraint(algorithm: ConstraintAlgorithm, columns: [Identifier], name: Identifier?) -> TableConstraint {
            return self.init(algorithm: algorithm, columns: columns, name: name)
        }
        
        private let algorithm: ConstraintAlgorithm
        private let columns: [Identifier]
        private let name: Identifier?
        
        public func serialize(_ binds: inout [Encodable]) -> String {
            #warning("serialize columns")
            if let name = self.name {
                return "CONSTRAINT " + name.serialize(&binds) + " " + algorithm.serialize(&binds)
            } else {
                return algorithm.serialize(&binds)
            }
        }
    }
}
