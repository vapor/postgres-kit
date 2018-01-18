import Async

extension PostgreSQLClient {
    /// Sends a parameterized PostgreSQL query command, collecting the parsed results.
    public func parameterizedQuery(
        _ string: String,
        _ parameters: [PostgreSQLData] = []
    ) throws -> Future<[[String: PostgreSQLData]]> {
        var rows: [[String: PostgreSQLData]] = []
        return try parameterizedQuery(string, parameters) { row in
            rows.append(row)
            }.map(to: [[String: PostgreSQLData]].self) {
                return rows
        }
    }

    /// Sends a parameterized PostgreSQL query command, returning the parsed results to
    /// the supplied closure.
    public func parameterizedQuery(
        _ string: String,
        _ parameters: [PostgreSQLData] = [],
        onRow: @escaping ([String: PostgreSQLData]) -> ()
    ) throws -> Future<Void> {
        let parse = PostgreSQLParseRequest(
            statementName: "",
            query: string,
            parameterTypes: parameters.map { .type(forData: $0) }
        )
        let describe = PostgreSQLDescribeRequest(type: .statement, name: "")
        var currentRow: PostgreSQLRowDescription?
        var currentParameters: PostgreSQLParameterDescription?
        return send([
            .parse(parse), .describe(describe), .sync
        ]) { message in
            switch message {
            case .parseComplete: break
            case .rowDescription(let row): currentRow = row
            case .parameterDescription(let parameters): currentParameters = parameters
            case .noData: break
            default: fatalError("Unexpected message during PostgreSQLParseRequest: \(message)")
            }
        }.flatMap(to: Void.self) {
            let parameterDataTypes = (currentParameters !! "Unexpected nil parameters").dataTypes
            let resultDataTypes = currentRow?.fields.map { $0.dataType } ?? [] // nil currentRow means no resutls

            // cache so we don't compute twice
            let _parameterFormats = parameterDataTypes.map { $0.preferredFormat }
            let _resultFormats = resultDataTypes.map { $0.preferredFormat }
            let bind = try PostgreSQLBindRequest(
                portalName: "",
                statementName: "",
                parameterFormatCodes: _parameterFormats,
                parameters: parameters.enumerated().map { try .make(data: $0.1, format: _parameterFormats[$0.0]) },
                resultFormatCodes: _resultFormats
            )
            let execute = PostgreSQLExecuteRequest(
                portalName: "",
                maxRows: 0
            )
            return self.send([
                .bind(bind), .execute(execute), .sync
            ]) { message in
                switch message {
                case .bindComplete: break
                case .dataRow(let data):
                    let row = currentRow !! "Unexpected PostgreSQLDataRow without preceding PostgreSQLRowDescription."
                    let parsed = try row.parse(data: data, formats: _resultFormats)
                    onRow(parsed)
                case .close: break
                case .noData: break
                default: fatalError("Unexpected message during PostgreSQLParseRequest: \(message)")
                }
            }
        }
    }
}

/// MARK: Codable

extension PostgreSQLClient {
    /// Sends a parameterized PostgreSQL query command, collecting the parsed results.
    public func parameterizedQuery(
        _ string: String,
        encoding parameters: [Encodable]
    ) throws -> Future<[[String: PostgreSQLData]]> {
        let parameters = try parameters.map { try PostgreSQLDataEncoder().encode($0) }
        return try parameterizedQuery(string, parameters)
    }

    /// Sends a parameterized PostgreSQL query command, returning the parsed results to
    /// the supplied closure.
    public func parameterizedQuery(
        _ string: String,
        encoding parameters: [Encodable],
        onRow: @escaping ([String: PostgreSQLData]) -> ()
    ) throws -> Future<Void> {
        let parameters = try parameters.map { try PostgreSQLDataEncoder().encode($0) }
        return try parameterizedQuery(string, parameters, onRow: onRow)
    }
}
