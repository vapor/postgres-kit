import SQLKit

extension PostgresQuery {
    public struct Expression: SQLExpression {
        public typealias Literal = PostgresQuery.Literal
        public typealias Bind = PostgresQuery.Bind
        public typealias ColumnIdentifier = PostgresQuery.ColumnIdentifier
        public typealias BinaryOperator = PostgresQuery.BinaryOperator
        public typealias Identifier = PostgresQuery.Identifier
        public typealias Subquery = PostgresQuery.Select
        
        
        public static func alias(_ expression: Expression, as name: Identifier) -> Expression {
            return self.init(.alias(expression, name))
        }
        
        public static func all(table: Identifier?) -> Expression {
            return self.init(.all(table))
        }
        
        public static func binary(_ lhs: Expression, _ op: BinaryOperator, _ rhs: Expression) -> Expression {
            return self.init(.binary(lhs, op, rhs))
        }
        
        public static func bind(_ bind: Bind) -> Expression {
            return self.init(.bind(bind))
        }
        
        public static func column(_ column: PostgresQuery.ColumnIdentifier) -> Expression {
            return self.init(.column(column))
        }
        
        public static func function(_ name: String, _ args: [PostgresQuery.Expression]) -> PostgresQuery.Expression {
            return self.init(.function(name, args))
        }
        
        public static func group(_ expressions: [Expression]) -> Expression {
            return self.init(.group(expressions))
        }
        
        public static func literal(_ literal: PostgresQuery.Literal) -> Expression {
            return self.init(.literal(literal))
        }
        
        
        public static func raw(_ string: String) -> Expression {
            return self.init(.raw(string))
        }
        
        public static func subquery(_ subquery: Select) -> Expression {
            return self.init(.subquery(subquery))
        }
        
        public var isNull: Bool {
            switch self.storage {
            case .literal(let literal): return literal.isNull
            default: return false
            }
        }
        
        private indirect enum Storage {
            case alias(Expression, Identifier)
            case all(Identifier?)
            case binary(Expression, BinaryOperator, Expression)
            case bind(Bind)
            case column(ColumnIdentifier)
            case group([Expression])
            case function(String, [Expression])
            case literal(Literal)
            case raw(String)
            case subquery(Select)
        }
        
        private let storage: Storage
        
        private init(_ storage: Storage) {
            self.storage = storage
        }
        
        public func serialize(_ binds: inout [Encodable]) -> String {
            switch self.storage {
            case .alias(let expr, let name): return expr.serialize(&binds) + " AS " + name.serialize(&binds)
            case .all(let table):
                if let table = table {
                    return table.serialize(&binds) + ".*"
                } else {
                    return "*"
                }
            case .binary(let lhs, let op, let rhs):
                switch rhs.storage {
                case .group(let group):
                    switch group.count {
                    case 0:
                        switch op {
                        case .in: return Expression.literal(.boolean(false)).serialize(&binds)
                        case .notIn: return Expression.literal(.boolean(true)).serialize(&binds)
                        default: break
                        }
                    case 1:
                        switch op {
                        case .in: return Expression.binary(lhs, .equal, group[0]).serialize(&binds)
                        case .notIn: return Expression.binary(lhs, .notEqual, group[0]).serialize(&binds)
                        default: break
                        }
                    default: break
                    }
                case .literal(let literal):
                    if literal.isNull {
                        switch op {
                        case .equal:
                            return lhs.serialize(&binds) + " IS NULL"
                        case .notEqual:
                            return lhs.serialize(&binds) + " IS NOT NULL"
                        default: break
                        }
                    }
                default: break
                }
                return lhs.serialize(&binds) + " " + op.serialize(&binds) + " " + rhs.serialize(&binds)
            case .bind(let bind): return bind.serialize(&binds)
            case .column(let column): return column.serialize(&binds)
            case .function(let name, let args): return name + "(" + args.serialize(&binds) + ")"
            case .group(let exprs): return "(" + exprs.serialize(&binds, joinedBy: ", ") + ")"
            case .literal(let literal): return literal.serialize(&binds)
            case .raw(let string): return string
            case .subquery(let subquery): return subquery.serialize(&binds)
            }
        }
        
        public init(stringLiteral value: String) {
            self.init(.column(.init(stringLiteral: value)))
        }
        
        public init(integerLiteral value: Int) {
            self.init(.literal(.numeric(value.description)))
        }
        
        public init(floatLiteral value: Double) {
            self.init(.literal(.numeric(value.description)))
        }
    }
}
