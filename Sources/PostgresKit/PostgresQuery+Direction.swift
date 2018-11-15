import SQLKit

extension PostgresQuery {
    #warning("rm need for direction type")
    public struct Direction: SQLDirection {
        public static var ascending: PostgresQuery.Direction {
            return .init(.ascending)
        }
        public static var descending: PostgresQuery.Direction {
            return .init(.descending)
        }
        
        private enum Storage {
            case ascending
            case descending
        }
        
        private let storage: Storage
        
        private init(_ storage: Storage) {
            self.storage = storage
        }
        
        public func serialize(_ binds: inout [Encodable]) -> String {
            switch self.storage {
            case .ascending: return "ASC"
            case .descending: return "DESC"
            }
        }
    }
}
