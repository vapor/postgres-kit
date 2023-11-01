import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxMacros

public enum PostgresRecordMacroType: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        if declaration.hasError { return [] }
        Diagnoser.shared = Diagnoser(context: context)

        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError.isNotStruct
        }
        let accessLevel = structDecl.accessLevelModifier.map { "\($0) " } ?? ""
        /// Compiler won't be able to infer what function to use when doing `PostgresRow.decode()`.
        let forbiddenProtocols = ["PostgresCodable", "PostgresDecodable"]
        let inheritedTypes = structDecl.inheritanceClause?.inheritedTypes ?? []
        for idx in inheritedTypes.indices {
            let proto = inheritedTypes[idx]
            let name = proto.trimmedDescription
            if forbiddenProtocols.contains(name) {
                Diagnoser.shared.cannotConformToProtocol(
                    name: name,
                    old: structDecl,
                    new: structDecl.removingInheritedType(at: idx)
                )
                return []
            }
        }

        let members = structDecl.memberBlock.members
        let variableDecls = members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
        let storedVariables = try variableDecls
            .flatMap(Variable.parse(from:))
            .filter { !($0.isStatic || $0.isComputed) }

        let name = structDecl.name.trimmedDescription
        let initializer = try storedVariables.makePostgresRecordInit(
            name: name,
            accessLevel: accessLevel
        )
        let codingKeys = storedVariables.makeCodingKeys(accessLevel: accessLevel)
        let postgresRecord = try ExtensionDeclSyntax("""
        extension \(raw: name): PostgresRecord {
        \(raw: initializer)
        \(raw: codingKeys)
        }
        """)

        return [postgresRecord]
    }
}
