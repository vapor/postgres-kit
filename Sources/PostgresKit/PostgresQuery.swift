import SQLKit

public struct PostgresQuery: SQLQuery {
    public struct AlterTable: SQLAlterTable {
        public typealias Identifier = PostgresQuery.Identifier
        public typealias ColumnDefinition = PostgresQuery.ColumnDefinition
        
        public static func alterTable(name: PostgresQuery.Identifier) -> AlterTable {
            return .init(table: name, columns: [])
        }
        
        public var table: PostgresQuery.Identifier
        public var columns: [PostgresQuery.ColumnDefinition]
        
        public func serialize(_ binds: inout [Encodable]) -> String {
            #warning("implement me")
            fatalError()
        }
    }
    
    public struct Identifier: SQLIdentifier {
        public static func identifier(_ string: String) -> Identifier {
            return self.init(stringLiteral: string)
        }
        
        public var string: String
        
        #warning("auto implement this?")
        public init(stringLiteral value: String) {
            self.string = value
        }
        
        public func serialize(_ binds: inout [Encodable]) -> String {
            return "\"" + string + "\""
        }
    }
    
    public struct ColumnDefinition: SQLColumnDefinition {
        public typealias ColumnIdentifier = PostgresQuery.ColumnIdentifier
        public typealias DataType = PostgresQuery.DataType
        public typealias ColumnConstraint = PostgresQuery.ColumnConstraint
        
        let column: PostgresQuery.ColumnIdentifier
        let dataType: PostgresQuery.DataType
        let constraints: [PostgresQuery.ColumnConstraint]
        
        public static func columnDefinition(
            _ column: PostgresQuery.ColumnIdentifier,
            _ dataType: PostgresQuery.DataType,
            _ constraints: [PostgresQuery.ColumnConstraint]
        ) -> PostgresQuery.ColumnDefinition {
            return self.init(column: column, dataType: dataType, constraints: constraints)
        }
        
        
        public func serialize(_ binds: inout [Encodable]) -> String {
            #warning("implement me")
            fatalError()
        }
    }
    
    public struct ColumnConstraint: SQLColumnConstraint {
        public typealias Identifier = PostgresQuery.Identifier
        public typealias ConstraintAlgorithm = PostgresQuery.ConstraintAlgorithm
        
        public let algorithm: PostgresQuery.ConstraintAlgorithm
        public let name: PostgresQuery.Identifier?
        
        public static func constraint(
            algorithm: PostgresQuery.ConstraintAlgorithm,
            name: PostgresQuery.Identifier?
        ) -> PostgresQuery.ColumnConstraint {
            return self.init(algorithm: algorithm, name: name)
        }
        
        public func serialize(_ binds: inout [Encodable]) -> String {
            #warning("implement me")
            fatalError()
        }
    }
    
    public struct ColumnIdentifier: SQLColumnIdentifier {
        public static func column(name: PostgresQuery.Identifier, table: PostgresQuery.Identifier?) -> PostgresQuery.ColumnIdentifier {
            return self.init(name: name, table: table)
        }
        
        public var table: PostgresQuery.Identifier?
        public var name: PostgresQuery.Identifier
        
        public typealias Identifier = PostgresQuery.Identifier
        
        public typealias StringLiteralType = String
        
        public init(name: PostgresQuery.Identifier, table: PostgresQuery.Identifier? = nil) {
            self.name = name
            self.table = table
        }
        
        public init(stringLiteral value: String) {
            self = .column(name: .identifier(value), table: nil)
        }
        
        public func serialize(_ binds: inout [Encodable]) -> String {
            if let table = table {
                return table.serialize(&binds) + "." + self.name.serialize(&binds)
            } else {
                return self.name.serialize(&binds)
            }
        }
    }
    
    public struct ConstraintAlgorithm: SQLConstraintAlgorithm {
        public typealias Expression = <#type#>
        
        public typealias Collation = <#type#>
        
        public typealias ForeignKey = <#type#>
        
        
    }
    
    public typealias BinaryOperator = <#type#>
    
    public typealias Bind = <#type#>
    
    public typealias CreateIndex = <#type#>
    
    public typealias CreateTable = <#type#>
    
    public typealias Collation = <#type#>
    
    public typealias Delete = <#type#>
    
    public typealias Distinct = <#type#>
    
    public typealias DropIndex = <#type#>
    
    public typealias DropTable = <#type#>
    
    public typealias Expression = <#type#>
    
    public typealias ForeignKey = <#type#>
    
    public typealias ForeignKeyAction = <#type#>
    
    public typealias GroupBy = <#type#>
    
    public typealias Insert = <#type#>
    
    public typealias IndexModifier = <#type#>
    
    public typealias Join = <#type#>
    
    public typealias Literal = <#type#>
    
    public typealias OrderBy = <#type#>
    
    public typealias Select = <#type#>
    
    public typealias TableConstraint = <#type#>
    
    public typealias Update = <#type#>
}
