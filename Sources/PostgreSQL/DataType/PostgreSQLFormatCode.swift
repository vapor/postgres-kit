/// The format code being used for the field.
/// Currently will be zero (text) or one (binary).
/// In a RowDescription returned from the statement variant of Describe,
/// the format code is not yet known and will always be zero.
public enum PostgreSQLFormatCode: Int16, Codable {
    case text = 0
    case binary = 1
}

public struct PostgreSQLResultFormat {
    /// The format codes
    internal let formatCodeFactory: ([PostgreSQLDataType]) -> [PostgreSQLFormatCode]

    /// Dynamically choose result format based on data type.
    public static func dynamic(_ callback: @escaping (PostgreSQLDataType) -> PostgreSQLFormatCode) -> PostgreSQLResultFormat {
        return .init { return $0.map { callback($0) } }
    }

    /// Request all of the results in a specific format.
    public static func all(_ code: PostgreSQLFormatCode) -> PostgreSQLResultFormat {
        return .init { _ in return [code] }
    }

    /// Request all of the results in a specific format.
    public static func text() -> PostgreSQLResultFormat {
        return .all(.text)
    }

    /// Request all of the results in a specific format.
    public static func binary() -> PostgreSQLResultFormat {
        return .all(.binary)
    }

    /// Let the server decide the formatting options.
    public static func notSpecified() -> PostgreSQLResultFormat {
        return .init { _ in return [] }
    }
}
