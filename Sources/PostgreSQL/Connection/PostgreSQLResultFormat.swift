public struct PostgreSQLResultFormat {
    /// The format codes
    internal let formatCodes: [PostgreSQLMessage.FormatCode]
    
    /// Request all of the results in a specific format.
    public static var text: PostgreSQLResultFormat {
        return .init(formatCodes: [.text])
    }

    /// Request all of the results in a specific format.
    public static var binary: PostgreSQLResultFormat {
        return .init(formatCodes: [.binary])
    }

    /// Let the server decide the formatting options.
    public static var unspecified: PostgreSQLResultFormat {
        return .init(formatCodes: [])
    }
}
