import SwiftSyntax

extension [Variable] {
    func makeCodingKeys(accessLevel: String) -> String {
        """
        \(accessLevel)enum CodingKeys: String, CodingKey {
        \(self.makeCodingKeysCases())
        }
        """
    }

    private func makeCodingKeysCases() -> String {
        return self.map(\.name).map { name in
            let snakeCaseName = name.convertedToSnakeCase()
            if snakeCaseName != name {
                return #"    case \#(name) = "\#(snakeCaseName)""#
            } else {
                return #"    case \#(name)"#
            }
        }
        .joined(separator: "\n")
    }
}
