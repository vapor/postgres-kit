import Async

extension PostgreSQLConnection {
    /// Sends a parameterized PostgreSQL query command, collecting the parsed results.
    public func query(
        _ string: String,
        _ parameters: [PostgreSQLDataConvertible] = []
    ) throws -> Future<[[PostgreSQLColumn: PostgreSQLData]]> {
        var rows: [[PostgreSQLColumn: PostgreSQLData]] = []
        return try query(string, parameters) { row in
            rows.append(row)
        }.map(to: [[PostgreSQLColumn: PostgreSQLData]].self) {
            return rows
        }
    }

    /// Sends a parameterized PostgreSQL query command, returning the parsed results to
    /// the supplied closure.
    public func query(
        _ string: String,
        _ parameters: [PostgreSQLDataConvertible] = [],
        resultFormat: PostgreSQLResultFormat = .binary(),
        onRow: @escaping ([PostgreSQLColumn: PostgreSQLData]) throws -> ()
    ) throws -> Future<Void> {
        let parameters = try parameters.map { try $0.convertToPostgreSQLData() }
        let parse = PostgreSQLParseRequest(
            statementName: "",
            query: string,
            parameterTypes: parameters.map { $0.type }
        )
        let describe = PostgreSQLDescribeRequest(
            type: .statement,
            name: ""
        )
        let bind = PostgreSQLBindRequest(
            portalName: "",
            statementName: "",
            parameterFormatCodes: parameters.map { $0.format },
            parameters: parameters.map { .init(data: $0.data) },
            resultFormatCodes: resultFormat.formatCodes
        )
        let execute = PostgreSQLExecuteRequest(
            portalName: "",
            maxRows: 0
        )

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
                    throw PostgreSQLError(identifier: "query", reason: "Unexpected PostgreSQLDataRow without preceding PostgreSQLRowDescription.", source: .capture())
                }
                let parsed = try row.parse(
                    data: data,
                    formatCodes: resultFormat.formatCodes,
                    tableNameCache: self.tableNameCache
                )
                try onRow(parsed)
            case .close: break
            default: throw PostgreSQLError(identifier: "query", reason: "Unexpected message during PostgreSQLParseRequest: \(message)", source: .capture())
            }
        }
    }
}
