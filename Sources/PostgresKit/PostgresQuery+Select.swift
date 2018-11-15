import SQLKit

extension PostgresQuery {
    /// See `SQLSelect`.
    public struct Select: SQLSelect {
        /// See `SQLSelect`.
        public typealias Distinct = PostgresQuery.Distinct
        
        /// See `SQLSelect`.
        public typealias Identifier = PostgresQuery.Identifier
        
        /// See `SQLSelect`.
        public typealias Join = PostgresQuery.Join
        
        /// See `SQLSelect`.
        public typealias Expression = PostgresQuery.Expression
        
        /// See `SQLSelect`.
        public typealias GroupBy = PostgresQuery.GroupBy
        
        /// See `SQLSelect`.
        public typealias OrderBy = PostgresQuery.OrderBy
        
        /// See `SQLSelect`.
        public static func select() -> Select {
            return .init()
        }
        
        /// See `SQLSelect`.
        public var distinct: Distinct?
        
        /// See `SQLSelect`.
        public var columns: [Expression]
        
        /// See `SQLSelect`.
        public var tables: [Identifier]
        
        /// See `SQLSelect`.
        public var joins: [Join]
        
        /// See `SQLSelect`.
        public var predicate: Expression?
        
        /// See `SQLSelect`.
        public var groupBy: [GroupBy]
        
        /// See `SQLSelect`.
        public var orderBy: [OrderBy]
        
        /// See `SQLSelect`.
        public var limit: Int?
        
        /// See `SQLSelect`.
        public var offset: Int?
        
        /// See `SQLSelect`.
        public init(
            distinct: Distinct? = nil,
            columns: [Expression] = [],
            tables: [Identifier] = [],
            joins: [Join] = [],
            predicate: Expression? = nil,
            groupBy: [GroupBy] = [],
            orderBy: [OrderBy] = [],
            limit: Int? = nil,
            offset: Int? = nil
        ) {
            self.distinct = distinct
            self.columns = columns
            self.tables = tables
            self.joins = joins
            self.predicate = predicate
            self.groupBy = groupBy
            self.orderBy = orderBy
            self.limit = limit
            self.offset = offset
        }
        public func serialize(_ binds: inout [Encodable]) -> String {
            var sql: [String] = []
            sql.append("SELECT")
            if let distinct = self.distinct {
                sql.append(distinct.serialize(&binds))
            }
            sql.append(columns.serialize(&binds))
            if !self.tables.isEmpty {
                sql.append("FROM")
                sql.append(self.tables.serialize(&binds))
            }
            if !self.joins.isEmpty {
                sql.append(self.joins.serialize(&binds, joinedBy: " "))
            }
            if let predicate = self.predicate {
                sql.append("WHERE")
                sql.append(predicate.serialize(&binds))
            }
            if !self.groupBy.isEmpty {
                sql.append("GROUP BY")
                sql.append(self.groupBy.serialize(&binds))
            }
            if !self.orderBy.isEmpty {
                sql.append("ORDER BY")
                sql.append(self.orderBy.serialize(&binds))
            }
            if let limit = self.limit {
                sql.append("LIMIT")
                sql.append(limit.description)
            }
            if let offset = self.offset {
                sql.append("OFFSET")
                sql.append(offset.description)
            }
            return sql.joined(separator: " ")
        }
        
    }
}

