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
        let diagnoser = Diagnoser(context: context)

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
                diagnoser.cannotConformToProtocol(
                    name: name,
                    old: structDecl,
                    new: structDecl.removingInheritedType(at: idx)
                )
                return []
            }
        }

        let members = structDecl.memberBlock.members
        let variableDecls = members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
        let variables = try variableDecls.flatMap(Variable.parse(from:))

        let name = structDecl.name.trimmedDescription
        let initializer = variables.makePostgresRecordInit(name: name, accessLevel: accessLevel)
        let postgresRecord = try ExtensionDeclSyntax("""
        extension \(raw: name): PostgresRecord {
        \(raw: initializer)
        }
        """)

        return [postgresRecord]
    }
}
