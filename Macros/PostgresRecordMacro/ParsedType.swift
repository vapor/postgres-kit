import SwiftSyntax

indirect enum ParsedType: CustomStringConvertible {

    enum Error: Swift.Error, CustomStringConvertible {
        case unknownParameterType(String)
        case failedToParse(Any.Type)

        var description: String {
            switch self {
            case let .unknownParameterType(type):
                return "unknownParameterType(\(type))"
            case let .failedToParse(type):
                return "failedToParse(\(type))"
            }
        }
    }

    case plain(String)
    case optional(of: Self)
    case array(of: Self)
    case dictionary(key: Self, value: Self)
    case member(base: Self, `extension`: String)
    case unknownGeneric(String, arguments: [Self])

    public var description: String {
        switch self {
        case let .plain(type):
            return type
        case let .optional(type):
            return "\(type)?"
        case let .array(type):
            return "[\(type)]"
        case let .dictionary(key, value):
            return "[\(key): \(value)]"
        case let .member(base, `extension`):
            return "\(base.description).\(`extension`)"
        case let .unknownGeneric(name, arguments: arguments):
            return "\(name)<\(arguments.map(\.description).joined(separator: ", "))>"
        }
    }

    public init(syntax: some TypeSyntaxProtocol) throws {
        if let type = syntax.as(IdentifierTypeSyntax.self) {
            let name = type.name.trimmedDescription
            if let genericArgumentClause = type.genericArgumentClause,
               !genericArgumentClause.arguments.isEmpty {
                let arguments = genericArgumentClause.arguments
                switch (arguments.count, name) {
                case (1, "Optional"):
                    self = try .optional(of: Self(syntax: arguments.first!.argument))
                case (1, "Array"):
                    self = try .array(of: Self(syntax: arguments.first!.argument))
                case (2, "Dictionary"):
                    let key = try Self(syntax: arguments.first!.argument)
                    let value = try Self(syntax: arguments.last!.argument)
                    self = .dictionary(key: key, value: value)
                default:
                    let arguments = try arguments.map(\.argument).map(Self.init(syntax:))
                    self = .unknownGeneric(name, arguments: arguments)
                }
            } else {
                self = .plain(name)
            }
        } else if let type = syntax.as(OptionalTypeSyntax.self) {
            self = try .optional(of: Self(syntax: type.wrappedType))
        } else if let type = syntax.as(ArrayTypeSyntax.self) {
            self = try .array(of: Self(syntax: type.element))
        } else if let type = syntax.as(DictionaryTypeSyntax.self) {
            let key = try Self(syntax: type.key)
            let value = try Self(syntax: type.value)
            self = .dictionary(key: key, value: value)
        } else if let type = syntax.as(MemberTypeSyntax.self) {
            let kind = try Self(syntax: type.baseType)
            self = .member(base: kind, extension: type.name.trimmedDescription)
        } else {
            throw Error.unknownParameterType(syntax.trimmed.description)
        }
    }
}
