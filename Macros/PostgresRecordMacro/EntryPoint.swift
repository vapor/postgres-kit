import SwiftSyntaxMacros
import SwiftCompilerPlugin

@main
struct PostgresRecordMacroEntryPoint: CompilerPlugin {
    static let macros: [String: any Macro.Type] = [
        "PostgresRecord": PostgresRecordMacroType.self
    ]

    let providingMacros: [any Macro.Type] = macros.map(\.value)

    init() { }
}
