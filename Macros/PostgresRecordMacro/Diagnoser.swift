import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

struct Diagnoser<Context: MacroExpansionContext> {
    let context: Context

    func cannotConformToProtocol(
        name: String,
        old: some SyntaxProtocol,
        new: some SyntaxProtocol
    ) {
        let diagnosis = Diagnosis.cannotConformToProtocol(name)
        context.diagnose(Diagnostic(
            node: old,
            position: old.position,
            message: diagnosis.diagnosticMessage,
            highlights: nil,
            notes: [],
            fixIt: .replace(
                message: diagnosis.fixItMessage,
                oldNode: old,
                newNode: new
            )
        ))
    }
}

private enum Diagnosis: Error {
    case cannotConformToProtocol(String)

    private struct _DiagnosticMessage: DiagnosticMessage {
        let parent: Diagnosis

        var message: String {
            switch parent {
            case let .cannotConformToProtocol(proto):
                return "Simultaneous conformance to '\(proto)' is not supported"
            }
        }

        var diagnosticID: SwiftDiagnostics.MessageID {
            .init(domain: "\(Self.self)", id: self.message)
        }

        var severity: SwiftDiagnostics.DiagnosticSeverity {
            .error
        }
    }

    private struct _FixItMessage: FixItMessage {
        let parent: Diagnosis

        var message: String {
            switch parent {
            case let .cannotConformToProtocol(proto):
                return "Remove conformance to '\(proto)'"
            }
        }

        var fixItID: SwiftDiagnostics.MessageID {
            .init(domain: "\(Self.self)", id: self.message)
        }
    }

    var diagnosticMessage: any DiagnosticMessage {
        _DiagnosticMessage(parent: self)
    }

    var fixItMessage: any FixItMessage {
        _FixItMessage(parent: self)
    }
}
