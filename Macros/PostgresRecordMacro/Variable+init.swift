import SwiftSyntax

extension [Variable] {
    func makePostgresRecordInit(name: String, accessLevel: String) throws -> String {
        try """
        \(accessLevel)init(
            _from row: PostgresRow,
            context: PostgresDecodingContext<some PostgresJSONDecoder>,
            file: String,
            line: Int
        ) throws {
            let decoded = try row.decode(
                \(makeType()),
                context: context,
                file: file,
                line: line
            )
        \(makeInitializations())
        }
        """
    }

    private func makeType() throws -> String {
        let count = self.count
        let variables = self.compactMap { variable -> Variable? in
            if variable.type == nil {
                Diagnoser.shared.typeSyntaxNotFound(name: variable.name, node: variable.binding)
                return nil
            } else {
                return variable
            }
        }
        /// Some variable had unexpected type.
        if count != variables.count {
            throw MacroError.vagueError
        } else {
            return "(\(variables.map(\.type!.description).joined(separator: ","))).self"
        }
    }

    private func makeInitializations() -> String {
        if self.count == 1 {
            return "    self.\(self[0].name) = decoded"
        } else {
            return self.enumerated().map { (idx, variable) in
                "    self.\(variable.name) = decoded.\(idx)"
            }.joined(separator: "\n")
        }
    }
}
