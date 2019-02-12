import SQLKit

public enum PostgresBinaryOperator: SQLExpression {
    /// @>
    case contains
    
    /// <@
    case isContainedBy
    
    /// &&
    case overlap
    
    /// `SQLExpression` conformance.
    public func serialize(to serializer: inout SQLSerializer) {
        switch self {
        case .contains:
            serializer.write("@>")
        case .isContainedBy:
            serializer.write("<@")
        case .overlap:
            serializer.write("&&")
        }
    }
}

//import SQLKit
//
//extension PostgresQuery {
//    /// See `SQLBinaryOperator`.
//    public struct BinaryOperator: SQLBinaryOperator {
//        #warning("convert to enum to make query size smaller")
//        /// See `SQLBinaryOperator`.
//        public static let add: BinaryOperator = "+"
//        
//        /// See `SQLBinaryOperator`.
//        public static let bitwiseAnd: BinaryOperator = "&"
//        
//        /// See `SQLBinaryOperator`.
//        public static let bitwiseOr: BinaryOperator = "|"
//        
//        /// See `SQLBinaryOperator`.
//        public static let bitwiseShiftLeft: BinaryOperator = "<<"
//        
//        /// See `SQLBinaryOperator`.
//        public static let bitwiseShiftRight: BinaryOperator = ">>"
//        
//        /// See `SQLBinaryOperator`.
//        public static let concatenate: BinaryOperator = "||"
//        
//        /// See `SQLBinaryOperator`.
//        public static let divide: BinaryOperator = "/"
//        
//        /// See `SQLBinaryOperator`.
//        public static let equal: BinaryOperator = "="
//        
//        /// See `SQLBinaryOperator`.
//        public static let greaterThan: BinaryOperator = ">"
//        
//        /// See `SQLBinaryOperator`.
//        public static let greaterThanOrEqual: BinaryOperator = ">="
//        
//        /// See `SQLBinaryOperator`.
//        public static let lessThan: BinaryOperator = "<"
//        
//        /// See `SQLBinaryOperator`.
//        public static let lessThanOrEqual: BinaryOperator = "<="
//        
//        /// See `SQLBinaryOperator`.
//        public static let modulo: BinaryOperator = "%"
//        
//        /// See `SQLBinaryOperator`.
//        public static let multiply: BinaryOperator = "*"
//        
//        /// See `SQLBinaryOperator`.
//        public static let notEqual: BinaryOperator = "!="
//        
//        /// See `SQLBinaryOperator`.
//        public static let subtract: BinaryOperator = "-"
//        
//        /// See `SQLBinaryOperator`.
//        public static let and: BinaryOperator = "AND"
//        
//        /// See `SQLBinaryOperator`.
//        public static let or: BinaryOperator = "OR"
//        
//        /// See `SQLBinaryOperator`.
//        public static let `in`: BinaryOperator = "IN"
//        
//        /// See `SQLBinaryOperator`.
//        public static let notIn: BinaryOperator = "NOT IN"
//        
//        /// See `SQLBinaryOperator`.
//        public static let `is`: BinaryOperator = "IS"
//        
//        /// See `SQLBinaryOperator`.
//        public static let isNot: BinaryOperator = "IS NOT"
//        
//        /// See `SQLBinaryOperator`.
//        public static let like: BinaryOperator = "LIKE"
//        
//        /// See `SQLBinaryOperator`.
//        public static let glob: BinaryOperator = "GLOB"
//        
//        /// See `SQLBinaryOperator`.
//        public static let match: BinaryOperator = "MATCH"
//        
//        /// See `SQLBinaryOperator`.
//        public static let regexp: BinaryOperator = "~"
//        
//        /// See `SQLBinaryOperator`.
//        public static let notLike: BinaryOperator = "NOT LIKE"
//        
//        /// See `SQLBinaryOperator`.
//        public static let notGlob: BinaryOperator = "NOT GLOB"
//        
//        /// See `SQLBinaryOperator`.
//        public static let notMatch: BinaryOperator = "NOT MATCH"
//        
//        /// See `SQLBinaryOperator`.
//        public static let notRegexp: BinaryOperator = "NOT REGEXP"
//        
//        /// See `SQLBinaryOperator`.
//        public static let ilike: BinaryOperator = "ILIKE"
//        
//        /// See `SQLBinaryOperator`.
//        public static let notILike: BinaryOperator = "NOT ILIKE"
//        
//        private let op: String
//        
//        public init(stringLiteral value: String) {
//            self.op = value
//        }
//        
//        public func serialize(_ binds: inout [Encodable]) -> String {
//            return op
//        }
//    }
//}
