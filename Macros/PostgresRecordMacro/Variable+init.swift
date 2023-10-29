import SwiftSyntax

extension [Variable] {
    func makePostgresRecordInit(name: String, accessLevel: String) -> String {
        """
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

    private func makeType() -> String {
        "(\(self.map(\.type.description).joined(separator: ","))).self"
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
