import SwiftSyntax
import SwiftSyntaxMacros

extension StructDeclSyntax {
    func removingInheritedType(at idx: InheritedTypeListSyntax.Index) -> Self {
        var new = self
        new.inheritanceClause?.inheritedTypes.remove(at: idx)
        /// Remove the colon after types name, in e.g. `MyTable: `, if no protocols are remaining.
        if new.inheritanceClause?.inheritedTypes.isEmpty == true {
            new.inheritanceClause = nil
        }
        return new.reformatted()
    }

    var accessLevelModifier: String? {
        let accessLevels: [Keyword] = [.open, .public, .package, .internal, .private, .fileprivate]
        for modifier in self.modifiers {
            guard case let .keyword(keyword) = modifier.name.tokenKind else {
                continue
            }
            if accessLevels.contains(keyword) {
                return modifier.name.trimmedDescription
            }
        }
        return nil
    }

    /// https://github.com/apple/swift/pull/69448
    /// Remove whenever this bug-fix is live (when swift 5.9.2 is out?)
    func conforms(to protocolName: String) -> Bool {
        self.inheritanceClause?.inheritedTypes.contains {
            $0.type.as(IdentifierTypeSyntax.self)?.name.trimmedDescription == protocolName
        } == true
    }
}

extension SyntaxProtocol {
    /// Build a syntax node from this `Buildable` and format it with the given format.
    func reformatted() -> Self {
        return self.formatted().as(Self.self)!
    }
}

extension DeclModifierListSyntax {
    func contains(_ keyword: Keyword) -> Bool {
        for modifier in self {
            guard case let .keyword(existingKeyword) = modifier.name.tokenKind else {
                continue
            }
            if keyword == existingKeyword {
                return true
            }
        }
        return false
    }
}
