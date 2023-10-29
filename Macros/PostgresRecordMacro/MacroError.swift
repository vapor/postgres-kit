import SwiftDiagnostics

enum MacroError: Error {
    case isNotStruct
}

extension MacroError: DiagnosticMessage {
    var message: String {
        switch self {
        case .isNotStruct:
            return "Only 'struct's are supported"
        }
    }

    var diagnosticID: MessageID {
        .init(domain: "PostgresRecordMacro.MacroError", id: self.message)
    }

    var severity: DiagnosticSeverity {
        .error
    }
}
