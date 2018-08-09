/// PostgreSQL specific `SQLBinaryOperator`.
public enum PostgreSQLBinaryOperator: SQLBinaryOperator, Equatable {
    /// See `SQLBinaryOperator`.
    public static var equal: PostgreSQLBinaryOperator { return ._equal }
    
    /// See `SQLBinaryOperator`.
    public static var notEqual: PostgreSQLBinaryOperator { return ._notEqual }
    
    /// See `SQLBinaryOperator`.
    public static var greaterThan: PostgreSQLBinaryOperator { return ._greaterThan }
    
    /// See `SQLBinaryOperator`.
    public static var lessThan: PostgreSQLBinaryOperator { return ._lessThan }
    
    /// See `SQLBinaryOperator`.
    public static var greaterThanOrEqual: PostgreSQLBinaryOperator { return ._greaterThanOrEqual }
    
    /// See `SQLBinaryOperator`.
    public static var lessThanOrEqual: PostgreSQLBinaryOperator { return ._lessThanOrEqual }
    
    /// See `SQLBinaryOperator`.
    public static var like: PostgreSQLBinaryOperator { return ._like }
    
    /// See `SQLBinaryOperator`.
    public static var notLike: PostgreSQLBinaryOperator { return ._notLike }
    
    /// See `SQLBinaryOperator`.
    public static var `in`: PostgreSQLBinaryOperator { return ._in }
    
    /// See `SQLBinaryOperator`.
    public static var `notIn`: PostgreSQLBinaryOperator { return ._notIn }
    
    /// See `SQLBinaryOperator`.
    public static var and: PostgreSQLBinaryOperator { return ._and }
    
    /// See `SQLBinaryOperator`.
    public static var or: PostgreSQLBinaryOperator { return ._or }
    
    /// See `SQLBinaryOperator`.
    public static var concatenate: PostgreSQLBinaryOperator { return ._concatenate }
    
    /// See `SQLBinaryOperator`.
    public static var multiply: PostgreSQLBinaryOperator { return ._multiply }
    
    /// See `SQLBinaryOperator`.
    public static var divide: PostgreSQLBinaryOperator { return ._divide }
    
    /// See `SQLBinaryOperator`.
    public static var modulo: PostgreSQLBinaryOperator { return ._modulo }
    
    /// See `SQLBinaryOperator`.
    public static var add: PostgreSQLBinaryOperator { return ._add }
    
    /// See `SQLBinaryOperator`.
    public static var subtract: PostgreSQLBinaryOperator { return ._subtract }
    
    
    /// `||`
    case _concatenate
    
    /// `*`
    case _multiply
    
    /// `/`
    case _divide
    
    /// `%`
    case _modulo
    
    /// `+`
    case _add
    
    /// `-`
    case _subtract
    
    /// `<<`
    case _bitwiseShiftLeft
    
    /// `>>`
    case _bitwiseShiftRight
    
    /// `&`
    case _bitwiseAnd
    
    /// `|`
    case _bitwiseOr
    
    /// `<`
    case _lessThan
    
    /// `<=`
    case _lessThanOrEqual
    
    /// `>`
    case _greaterThan
    
    /// `>=`
    case _greaterThanOrEqual
    
    /// `=` or `==`
    case _equal
    
    /// `!=` or `<>`
    case _notEqual
    
    /// `AND`
    case _and
    
    /// `OR`
    case _or
    
    /// `IS`
    case _is
    
    /// `IS NOT`
    case _isNot
    
    /// `IN`
    case _in
    
    /// `NOT IN`
    case _notIn
    
    /// `LIKE`
    case _like
    
    /// `NOT LIKE`
    case _notLike
    
    /// `GLOB`
    case _glob
    
    /// `NOT GLOB`
    case _notGlob
    
    /// `MATCH`
    case _match
    
    /// `NOT MATCH`
    case _notMatch
    
    /// `REGEXP`
    case _regexp
    
    /// `NOT REGEXP`
    case _notRegexp
    
    /// `ILIKE`
    case ilike
    
    /// `NOT ILIKE`
    case notILike
    
    /// Custom operator
    case custom(String)
    
    /// See `SQLSerializable`.
    public func serialize(_ binds: inout [Encodable]) -> String {
        switch self {
        case ._add: return "+"
        case ._bitwiseAnd: return "&"
        case ._bitwiseOr: return "|"
        case ._bitwiseShiftLeft: return "<<"
        case ._bitwiseShiftRight: return ">>"
        case ._concatenate: return "||"
        case ._divide: return "/"
        case ._equal: return "="
        case ._greaterThan: return ">"
        case ._greaterThanOrEqual: return ">="
        case ._lessThan: return "<"
        case ._lessThanOrEqual: return "<="
        case ._modulo: return "%"
        case ._multiply: return "*"
        case ._notEqual: return "!="
        case ._subtract: return "-"
        case ._and: return "AND"
        case ._or: return "OR"
        case ._in: return "IN"
        case ._notIn: return "NOT IN"
        case ._is: return "IS"
        case ._isNot: return "IS NOT"
        case ._like: return "LIKE"
        case ._glob: return "GLOB"
        case ._match: return "MATCH"
        case ._regexp: return "~"
        case ._notLike: return "NOT LIKE"
        case ._notGlob: return "NOT GLOB"
        case ._notMatch: return "NOT MATCH"
        case ._notRegexp: return "NOT REGEXP"
        case .ilike: return "ILIKE"
        case .notILike: return "NOT ILIKE"
        case .custom(let op): return op
        }
    }
}
