import Async

extension PostgreSQLConnection {
    /// Sends a parameterized PostgreSQL query command, collecting the parsed results.
    public func query(
        _ string: String,
        _ parameters: [PostgreSQLDataCustomConvertible] = []
    ) throws -> Future<[[String: PostgreSQLData]]> {
        var rows: [[String: PostgreSQLData]] = []
        return try query(string, parameters) { row in
            rows.append(row)
        }.map(to: [[String: PostgreSQLData]].self) {
            return rows
        }
    }

    /// Sends a parameterized PostgreSQL query command, returning the parsed results to
    /// the supplied closure.
    public func query(
        _ string: String,
        _ parameters: [PostgreSQLDataCustomConvertible] = [],
        onRow: @escaping ([String: PostgreSQLData]) -> ()
    ) throws -> Future<Void> {
        let parameters = try parameters.map { try $0.convertToPostgreSQLData() }
        logger?.log(query: string, parameters: parameters)
        let parse = PostgreSQLParseRequest(
            statementName: "",
            query: string,
            parameterTypes: parameters.map { $0.type }
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
//            let parameterDataTypes = currentParameters?.dataTypes ?? [] // no parameters
//            let resultDataTypes = currentRow?.fields.map { $0.dataType } ?? [] // nil currentRow means no resutls

            // cache so we don't compute twice
            let bind = PostgreSQLBindRequest(
                portalName: "",
                statementName: "",
                parameterFormatCodes: parameters.map { $0.format },
                parameters: parameters.map { .init(data: $0.data) },
                resultFormatCodes: [.text]
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
                    let parsed = try row.parse(data: data)
                    onRow(parsed)
                case .close: break
                case .noData: break
                default: fatalError("Unexpected message during PostgreSQLParseRequest: \(message)")
                }
            }
        }
    }
}
