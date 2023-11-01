import SwiftDiagnostics

enum MacroError: Error {
    case isNotStruct
    case vagueError
}

extension MacroError: DiagnosticMessage {
    var message: String {
        switch self {
        case .isNotStruct:
            return "Only 'struct's are supported"
        case .vagueError:
            return "'PostgresRecord' macro expansion failed"
        }
    }

    var diagnosticID: MessageID {
        .init(domain: "PostgresRecordMacro.MacroError", id: self.message)
    }

    var severity: DiagnosticSeverity {
        .error
    }
}
