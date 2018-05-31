extension PostgreSQLConnection {
    /// Runs a parameterized `Query`, returning the results as an array of rows.
    ///
    ///     let users = conn.query(.select(.all, from: "users"))
    ///
    /// Any values bound to the `DataQuery` as placeholders will be sent as query parameters.
    ///
    /// - parameters:
    ///     - query: `Query` to execute.
    /// - returns: A future array of results.
    public func query(_ q: Query) -> Future<[[PostgreSQLColumn: PostgreSQLData]]> {
        var rows: [[PostgreSQLColumn: PostgreSQLData]] = []
        return query(q) { row in
            rows.append(row)
        }.map {
            return rows
        }
    }
    
    /// Runs a parameterized `Query`, returning each row of the results to the supplied handler one at a time.
    ///
    ///     try conn.query(.select(.all, from: "users")) { row in
    ///         print(row)
    ///     }
    ///
    /// Any values bound to the `DataQuery` as placeholders will be sent as query parameters.
    ///
    /// - parameters:
    ///     - query: `Query` to execute.
    ///     - resultFormat: Desired `PostgreSQLResultFormat` to request from PostgreSQL. Defaults to `.binary`.
    ///     - onRow: PostgreSQL row accepting closure to handle results, if any.
    /// - returns: A future that signals query completion.
    public func query(_ q: Query, resultFormat: PostgreSQLResultFormat = .binary, onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) throws -> ()) -> Future<Void> {
        var binds = Binds()
        let sql = PostgreSQLSerializer().serialize(query: q, binds: &binds)
        do {
            let parameters = try binds.values.map { try PostgreSQLDataEncoder().encode($0) }
            return query(sql, parameters, resultFormat: resultFormat, onRow: onRow)
        } catch {
            return future(error: error)
        }
    }
    
    /// Runs a pre-serialized SQL query string, returning the results as an array of rows.
    ///
    ///     let users = conn.query("SELECT * FROM users")
    ///
    /// Query strings with placeholders can supply an array of parameterized values to be sent.
    ///
    ///     let users = conn.query("SELECT * FROM users WHERE name = $1", ["vapor"])
    ///
    /// - parameters:
    ///     - query: SQL `String` to execute.
    ///     - parameters: Array of `PostgreSQLDataConvertible` to bind.
    /// - returns: A future array of results.
    public func query(_ string: String, _ parameters: [PostgreSQLDataConvertible] = []) -> Future<[[PostgreSQLColumn: PostgreSQLData]]> {
        var rows: [[PostgreSQLColumn: PostgreSQLData]] = []
        return query(string, parameters) { row in
            rows.append(row)
        }.map {
            return rows
        }
    }

    /// Runs a pre-serialized SQL query string, returning each row of the results to the supplied handler one at a time.
    ///
    ///     let users = conn.query("SELECT * FROM users") { user in
    ///         print(user) // [PostgreSQLColumn: PostgreSQLData]
    ///     }
    ///
    /// Query strings with placeholders can supply an array of parameterized values to be sent.
    ///
    ///     let users = conn.query("SELECT * FROM users WHERE name = $1", ["vapor"]) { user in
    ///         print(user) // [PostgreSQLColumn: PostgreSQLData]
    ///     }
    ///
    /// - parameters:
    ///     - query: SQL `String` to execute.
    ///     - parameters: Array of `PostgreSQLDataConvertible` to bind.
    ///     - resultFormat: Desired `PostgreSQLResultFormat` to request from PostgreSQL. Defaults to `.binary`.
    ///     - onRow: PostgreSQL row accepting closure to handle results, if any.
    /// - returns: A future array of results.
    public func query(_ string: String, _ parameters: [PostgreSQLDataConvertible] = [], resultFormat: PostgreSQLResultFormat = .binary, onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) throws -> ()) -> Future<Void> {
        return operation {
            do {
                return try self._query(string, parameters, resultFormat: resultFormat, onRow: onRow)
            } catch {
                return self.eventLoop.newFailedFuture(error: error)
            }
        }
    }
    
    // MARK: Private

    /// Non-operation bounded query.
    private func _query(_ string: String, _ parameters: [PostgreSQLDataConvertible] = [], resultFormat: PostgreSQLResultFormat, onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) throws -> ()) throws -> Future<Void> {
        print(string)
        print(parameters)
        let parameters = try parameters.map { try $0.convertToPostgreSQLData() }
        logger?.record(query: string, values: parameters.map { $0.description })

        let parse = PostgreSQLParseRequest(statementName: "", query: string, parameterTypes: parameters.map { $0.type })
        let describe = PostgreSQLDescribeRequest(type: .statement, name: "")
        let bind = PostgreSQLBindRequest(
            portalName: "",
            statementName: "",
            parameterFormatCodes: parameters.map { $0.format },
            parameters: parameters.map { .init(data: $0.data) },
            resultFormatCodes: resultFormat.formatCodes
        )
        let execute = PostgreSQLExecuteRequest(portalName: "", maxRows: 0)
        var currentRow: PostgreSQLRowDescription?
        return self.send([
            .parse(parse), .describe(describe), .bind(bind), .execute(execute), .sync
        ]) { message in
            switch message {
            case .parseComplete: break
            case .parameterDescription: break
            case .noData: break
            case .bindComplete: break
            case .rowDescription(let row): currentRow = row
            case .dataRow(let data):
                guard let row = currentRow else {
                    throw PostgreSQLError(identifier: "query", reason: "Unexpected `PostgreSQLDataRow` without preceding `PostgreSQLRowDescription`.", source: .capture())
                }
                let parsed = try row.parse(data: data, formatCodes: resultFormat.formatCodes)
                try onRow(parsed)
            case .close: break
            default: throw PostgreSQLError(identifier: "query", reason: "Unexpected message during `PostgreSQLParseRequest`: \(message)", source: .capture())
            }
        }
    }
}
