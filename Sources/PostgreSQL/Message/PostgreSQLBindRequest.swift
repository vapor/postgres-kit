import Bits
import Foundation

/// Identifies the message as a Bind command.
struct PostgreSQLBindRequest: Encodable {
    /// The name of the destination portal (an empty string selects the unnamed portal).
    var portalName: String

    /// The name of the source prepared statement (an empty string selects the unnamed prepared statement).
    var statementName: String

    /// The number of parameter format codes that follow (denoted C below).
    /// This can be zero to indicate that there are no parameters or that the parameters all use the default format (text);
    /// or one, in which case the specified format code is applied to all parameters; or it can equal the actual number of parameters.
    /// The parameter format codes. Each must presently be zero (text) or one (binary).
    var parameterFormatCodes: [PostgreSQLFormatCode]

    /// The number of parameter values that follow (possibly zero). This must match the number of parameters needed by the query.
    var parameters: [PostgreSQLBindParameter]

    /// The number of result-column format codes that follow (denoted R below).
    /// This can be zero to indicate that there are no result columns or that the result columns should all use the default format (text);
    /// or one, in which case the specified format code is applied to all result columns (if any);
    /// or it can equal the actual number of result columns of the query.
    var resultFormatCodes: [PostgreSQLFormatCode]
}

struct PostgreSQLBindParameter: Encodable {
    /// The value of the parameter, in the format indicated by the associated format code. n is the above length.
    var data: Data?

    /// Serializes the `PostgreSQLData` to this parameter.
    static func make(data: PostgreSQLData, format: PostgreSQLFormatCode) throws -> PostgreSQLBindParameter {
        return try .init(data: data.serialize(format: format))
    }
}
