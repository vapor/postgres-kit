//import SQLKit
//
//extension PostgresQuery {
//    public struct Identifier: SQLIdentifier {
//        public static func identifier(_ string: String) -> Identifier {
//            return self.init(stringLiteral: string)
//        }
//        
//        public var string: String
//        
//        #warning("auto implement this?")
//        public init(stringLiteral value: String) {
//            self.string = value
//        }
//        
//        public func serialize(_ binds: inout [Encodable]) -> String {
//            return "\"" + string + "\""
//        }
//    }
//}
