extension PostgreSQLConnection {
    /// Runs a query, returning each row to the supplied handler.
    ///
    ///     try conn.query(.select(.all, from: "users")) { row in
    ///         print(row)
    ///     }
    ///
    /// Any values bound to the `DataQuery` as placeholders will be sent as query parameters.
    ///
    /// - parameters:
    ///     - query: `Query` to execute.
    ///     - onRow: PostgreSQL row accepting closure to handle results, if any.
    /// - returns: A future that signals query completion.
    public func query(_ query: PostgreSQLQuery, _ onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) throws -> ()) -> Future<Void> {
        return self.query(query, resultFormat: .binary, onRow)
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
    public func query(_ query: PostgreSQLQuery, resultFormat: PostgreSQLResultFormat, _ onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) throws -> ()) -> Future<Void> {
        var binds: [Encodable] = []
        let sql = query.serialize(&binds)
        return operation {
            do {
                return try self._query(sql, binds.map { try PostgreSQLDataEncoder().encode($0) }, resultFormat: resultFormat, onRow)
            } catch {
                return self.eventLoop.newFailedFuture(error: error)
            }
        }
    }

    /// Executes a raw query with the given parameters returning each row to the supplied handler.
    ///
    ///     try conn.query("SELECT id, firstName FROM users WHERE firstName = $1", ["Billy"]) { row in
    ///         print(row)
    ///     }
    ///
    /// - parameters:
    ///   - query: The raw query string to execute.
    ///   - resultFormat: Desired `PostgreSQLResultFormat` to request from PostgreSQL. Defaults to `.binary`.
    ///   - onRow: PostgreSQL row accepting closure to handle results, if any.
    public func query(_ query: String, _ parameters: [PostgreSQLDataConvertible] = [], resultFormat: PostgreSQLResultFormat = .binary,
                      _ onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) throws -> ()) -> Future<Void>
    {
        return operation {
            do {
                return try self._query(query, parameters.map { try $0.convertToPostgreSQLData() }, resultFormat: resultFormat, onRow)
            } catch {
                return self.eventLoop.newFailedFuture(error: error)
            }
        }
    }

    // MARK: Private

    /// Non-operation bounded query.
    private func _query(_ string: String, _ parameters: [PostgreSQLData] = [], resultFormat: PostgreSQLResultFormat, _ onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) throws -> ()) throws -> Future<Void> {
        logger?.record(query: string, values: parameters.map { $0.description })
        var currentRow: PostgreSQLMessage.RowDescription?
        return self.send([
            .parse(.init(statementName: "", query: string, parameterTypes: parameters.map { $0.type })),
            .describe(.init(command: .statement, name: "")),
            .bind(.init(
                portalName: "",
                statementName: "",
                parameterFormatCodes: parameters.map {
                    switch $0.storage {
                    case .text: return .text
                    case .binary, .null: return .binary
                    }
                },
                parameters: parameters.map {
                    switch $0.storage {
                    case .text(let string):  return .init(data: Data(string.utf8))
                    case .binary(let data): return .init(data: data)
                    case .null: return .init(data: nil)
                    }
                },
                resultFormatCodes: resultFormat.formatCodes
            )),
            .execute(.init(portalName: "", maxRows: 0)),
            .sync
        ]) { message in
            switch message {
            case .parseComplete: break
            case .parameterDescription: break
            case .noData: break
            case .bindComplete: break
            case .rowDescription(let row): currentRow = row
            case .dataRow(let data):
                guard let row = currentRow else {
                    throw PostgreSQLError(identifier: "query", reason: "Unexpected `PostgreSQLDataRow` without preceding `PostgreSQLRowDescription`.")
                }
                let parsed = try row.parse(data: data, formatCodes: resultFormat.formatCodes)
                try onRow(parsed)
            case .close: break
            default: throw PostgreSQLError(identifier: "query", reason: "Unexpected message during `PostgreSQLParseRequest`: \(message)")
            }
        }
    }
}
