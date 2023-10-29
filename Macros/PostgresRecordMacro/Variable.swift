import SwiftSyntax

struct Variable {

    enum Error: Swift.Error, CustomStringConvertible {
        case unsupportedPattern(String)
        case typeSyntaxNotFound(name: String)

        var description: String {
            switch self {
            case let .unsupportedPattern(pattern):
                return "unsupportedPattern(\(pattern))"
            case let .typeSyntaxNotFound(name):
                return "typeSyntaxNotFound(name: \(name))"
            }
        }
    }

    let name: String
    let type: ParsedType

    static func parse(from element: VariableDeclSyntax) throws -> [Variable] {
        try element.bindings.map { binding in
            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                throw Error.unsupportedPattern(binding.pattern.trimmedDescription)
            }
            let name = pattern.identifier.trimmed.text

            guard let typeSyntax = binding.typeAnnotation?.type else {
                throw Error.typeSyntaxNotFound(name: name)
            }
            let type = try ParsedType(syntax: typeSyntax)

            return Variable(name: name, type: type)
        }
    }
}
