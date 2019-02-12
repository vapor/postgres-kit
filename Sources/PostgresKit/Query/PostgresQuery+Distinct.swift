//import SQLKit
//
//extension PostgresQuery {
//    public struct Distinct: SQLDistinct {
//        public static var all: PostgresQuery.Distinct {
//            return self.init(.all)
//        }
//        
//        public static var distinct: PostgresQuery.Distinct {
//            return self.init(.distinct)
//        }
//        
//        private enum Storage {
//            case all
//            case distinct
//        }
//        
//        private let storage: Storage
//        
//        private init(_ storage: Storage) {
//            self.storage = storage
//        }
//        
//        public func serialize(_ binds: inout [Encodable]) -> String {
//            switch self.storage {
//            case .all: return "ALL"
//            case .distinct: return "DISTINCT"
//            }
//        }
//    }
//}
