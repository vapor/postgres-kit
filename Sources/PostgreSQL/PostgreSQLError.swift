import Debugging
import COperatingSystem

/// Errors that can be thrown while working with PostgreSQL.
public struct PostgreSQLError: Debuggable {
    public static let readableName = "PostgreSQL Error"
    public let identifier: String
    public var reason: String
    public var sourceLocation: SourceLocation
    public var stackTrace: [String]
    public var possibleCauses: [String]
    public var suggestedFixes: [String]

    /// Create a new TCP error.
    public init(
        identifier: String,
        reason: String,
        possibleCauses: [String] = [],
        suggestedFixes: [String] = [],
        source: SourceLocation
    ) {
        self.identifier = identifier
        self.reason = reason
        self.sourceLocation = source
        self.stackTrace = PostgreSQLError.makeStackTrace()
        self.possibleCauses = possibleCauses
        self.suggestedFixes = suggestedFixes
    }
}

func VERBOSE(_ string: @autoclosure () -> (String)) {
    #if VERBOSE
    print("[VERBOSE] [PostgreSQL] \(string())")
    #endif
}
