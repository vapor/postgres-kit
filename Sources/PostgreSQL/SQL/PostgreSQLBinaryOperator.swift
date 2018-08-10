/// PostgreSQL specific `SQLBinaryOperator`.
public struct PostgreSQLBinaryOperator: SQLBinaryOperator, Equatable, ExpressibleByStringLiteral {
    /// See `SQLBinaryOperator`.
    public static let add = PostgreSQLBinaryOperator("+")

    /// See `SQLBinaryOperator`.
    public static let bitwiseAnd = PostgreSQLBinaryOperator("&")

    /// See `SQLBinaryOperator`.
    public static let bitwiseOr = PostgreSQLBinaryOperator("|")

    /// See `SQLBinaryOperator`.
    public static let bitwiseShiftLeft = PostgreSQLBinaryOperator("<<")

    /// See `SQLBinaryOperator`.
    public static let bitwiseShiftRight = PostgreSQLBinaryOperator(">>")

    /// See `SQLBinaryOperator`.
    public static let concatenate = PostgreSQLBinaryOperator("||")

    /// See `SQLBinaryOperator`.
    public static let divide = PostgreSQLBinaryOperator("/")

    /// See `SQLBinaryOperator`.
    public static let equal = PostgreSQLBinaryOperator("=")

    /// See `SQLBinaryOperator`.
    public static let greaterThan = PostgreSQLBinaryOperator(">")

    /// See `SQLBinaryOperator`.
    public static let greaterThanOrEqual = PostgreSQLBinaryOperator(">=")

    /// See `SQLBinaryOperator`.
    public static let lessThan = PostgreSQLBinaryOperator("<")

    /// See `SQLBinaryOperator`.
    public static let lessThanOrEqual = PostgreSQLBinaryOperator("<=")

    /// See `SQLBinaryOperator`.
    public static let modulo = PostgreSQLBinaryOperator("%")

    /// See `SQLBinaryOperator`.
    public static let multiply = PostgreSQLBinaryOperator("*")

    /// See `SQLBinaryOperator`.
    public static let notEqual = PostgreSQLBinaryOperator("!=")

    /// See `SQLBinaryOperator`.
    public static let subtract = PostgreSQLBinaryOperator("-")

    /// See `SQLBinaryOperator`.
    public static let and = PostgreSQLBinaryOperator("AND")

    /// See `SQLBinaryOperator`.
    public static let or = PostgreSQLBinaryOperator("OR")

    /// See `SQLBinaryOperator`.
    public static let `in` = PostgreSQLBinaryOperator("IN")

    /// See `SQLBinaryOperator`.
    public static let notIn = PostgreSQLBinaryOperator("NOT IN")

    /// See `SQLBinaryOperator`.
    public static let `is` = PostgreSQLBinaryOperator("IS")

    /// See `SQLBinaryOperator`.
    public static let isNot = PostgreSQLBinaryOperator("IS NOT")

    /// See `SQLBinaryOperator`.
    public static let like = PostgreSQLBinaryOperator("LIKE")

    /// See `SQLBinaryOperator`.
    public static let glob = PostgreSQLBinaryOperator("GLOB")

    /// See `SQLBinaryOperator`.
    public static let match = PostgreSQLBinaryOperator("MATCH")

    /// See `SQLBinaryOperator`.
    public static let regexp = PostgreSQLBinaryOperator("~")

    /// See `SQLBinaryOperator`.
    public static let notLike = PostgreSQLBinaryOperator("NOT LIKE")

    /// See `SQLBinaryOperator`.
    public static let notGlob = PostgreSQLBinaryOperator("NOT GLOB")

    /// See `SQLBinaryOperator`.
    public static let notMatch = PostgreSQLBinaryOperator("NOT MATCH")

    /// See `SQLBinaryOperator`.
    public static let notRegexp = PostgreSQLBinaryOperator("NOT REGEXP")

    /// See `SQLBinaryOperator`.
    public static let ilike = PostgreSQLBinaryOperator("ILIKE")

    /// See `SQLBinaryOperator`.
    public static let notILike = PostgreSQLBinaryOperator("NOT ILIKE")

    public let op: String

    public init(_ op: String) {
        self.op = op
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public func serialize(_ binds: inout [Encodable]) -> String {
        return op
    }
}
