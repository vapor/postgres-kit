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
    internal let formatCodes: [PostgreSQLFormatCode]

    /// Request all of the results in a specific format.
    public static func all(_ code: PostgreSQLFormatCode) -> PostgreSQLResultFormat {
        return .init(formatCodes: [code])
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
        return .init(formatCodes: [])
    }

    /// Request all of the results in a specific format.
    public static func specific(_ codes: [PostgreSQLFormatCode]) -> PostgreSQLResultFormat {
        return .init(formatCodes: codes)
    }
}
