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

    func unsupportedPattern(_ pattern: String, node: some SyntaxProtocol) {
        let diagnosis = Diagnosis.unsupportedPattern(pattern)
        context.diagnose(Diagnostic(
            node: node,
            position: node.position,
            message: diagnosis.diagnosticMessage,
            highlights: nil,
            notes: [],
            fixIt: .init(
                message: diagnosis.fixItMessage,
                changes: []
            )
        ))
    }

    func typeSyntaxNotFound(name: String, node: some SyntaxProtocol) {
        let diagnosis = Diagnosis.typeSyntaxNotFound(name: name)
        context.diagnose(Diagnostic(
            node: node,
            position: node.position,
            message: diagnosis.diagnosticMessage,
            highlights: nil,
            notes: [],
            fixIt: .init(
                message: diagnosis.fixItMessage,
                changes: []
            )
        ))
    }
}

private enum Diagnosis: Error {
    case cannotConformToProtocol(String)
    case unsupportedPattern(String)
    case typeSyntaxNotFound(name: String)

    private struct _DiagnosticMessage: DiagnosticMessage {
        let parent: Diagnosis

        var message: String {
            switch parent {
            case let .cannotConformToProtocol(proto):
                return "Simultaneous conformance to '\(proto)' is not supported"
            case let .unsupportedPattern(pattern):
                return "Pattern of '\(pattern)' is unsupported. Please file and issue in at https://github.com/vapor/postgres-kit/issues"
            case let .typeSyntaxNotFound(name):
                return "Type declaration was not found for property '\(name)'."
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
            case .unsupportedPattern:
                return "As a workaround, try to use a more common pattern."
            case .typeSyntaxNotFound:
                return "Please provide an explicit type."
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
