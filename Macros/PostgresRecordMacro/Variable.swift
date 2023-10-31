import SwiftSyntax
import SwiftSyntaxMacros

struct Variable {
    let name: String
    let isStatic: Bool
    let isComputed: Bool
    let type: ParsedType

    static func parse(
        from element: VariableDeclSyntax,
        diagnoser: Diagnoser<some MacroExpansionContext>
    ) throws -> [Variable] {
        let isStatic = element.modifiers.contains(.static)
        return try element.bindings.compactMap { binding -> Variable? in
            let isComputed = binding.accessorBlock.map({ Self.isComputed($0.accessors) }) ?? false
            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                diagnoser.unsupportedPattern(
                    binding.pattern.trimmedDescription,
                    node: binding.pattern
                )
                return nil
            }
            let name = pattern.identifier.trimmed.text

            guard let typeSyntax = binding.typeAnnotation?.type else {
                diagnoser.typeSyntaxNotFound(name: name, node: binding)
                return nil
            }
            let type = try ParsedType(syntax: typeSyntax)

            return Variable(
                name: name,
                isStatic: isStatic,
                isComputed: isComputed,
                type: type
            )
        }
    }

    private static func isComputed(_ accessors: AccessorBlockSyntax.Accessors) -> Bool {
        if accessors.is(CodeBlockItemListSyntax.self) { return true }
        guard let accessors = accessors.as(AccessorDeclListSyntax.self) else {
            return false
        }
        for accessor in accessors {
            guard case let .keyword(keyword) = accessor.accessorSpecifier.tokenKind else {
                continue
            }
            if ![.didSet, .willSet].contains(keyword) {
                return true
            }
        }
        return false
    }
}
