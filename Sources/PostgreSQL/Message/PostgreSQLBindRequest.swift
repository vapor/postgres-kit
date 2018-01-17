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
    static func serialize(data: PostgreSQLData) throws -> PostgreSQLBindParameter {
        let serialized: Data?
        switch data {
        case .string(let string): serialized = Data(string.utf8)
        case .null: serialized = nil
        case .int8(let int): serialized = Data(int.bytes)
        case .int16(let int): serialized = Data(int.bytes)
        case .int32(let int): serialized = Data(int.bytes)
        case .int(let int): serialized = Data(int.bytes)
        case .uint8(let int): serialized = Data(int.bytes)
        case .uint16(let int): serialized = Data(int.bytes)
        case .uint32(let int): serialized = Data(int.bytes)
        case .uint(let int): serialized = Data(int.bytes)
        case .double(let double): serialized = Data(double.bytes)
        case .float(let float): serialized = Data(float.bytes)
        case .data(let data): serialized = data
        case .date(let date): serialized = Data(date.description.utf8)
        }
        return .init(data: serialized)
    }
}

extension FixedWidthInteger {
    /// Big-endian bytes for this integer.
    var bytes: [UInt8] {
        var bytes = [UInt8](repeating: 0, count: Self.bitWidth / 8)
        var intNetwork = bigEndian
        memcpy(&bytes, &intNetwork, bytes.count)
        return bytes
    }
}

extension FloatingPoint {
    /// Big-endian bytes for this floating-point number.
    var bytes: [UInt8] {
        var bytes = [UInt8](repeating: 0, count: MemoryLayout<Self>.size)
        var copy = self
        memcpy(&bytes, &copy, bytes.count)
        return bytes.reversed()
    }
}
