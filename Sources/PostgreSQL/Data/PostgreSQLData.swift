import Foundation

/// Supported `PostgreSQLData` data types.
public struct PostgreSQLData {
    /// The data's type.
    public var type: PostgreSQLDataType

    /// The data's format.
    public var format: PostgreSQLFormatCode

    /// The actual data.
    public var data: Data?

    public init(type: PostgreSQLDataType, format: PostgreSQLFormatCode = .binary, data: Data? = nil) {
        self.type = type
        self.format = format
        self.data = data
    }
}

extension PostgreSQLData: CustomStringConvertible {
    /// See `CustomStringConvertible.description`
    public var description: String {
        return "\(type) (\(format)) \(data?.hexDebug ?? "nil")"
    }
}

/// MARK: Equatable

extension PostgreSQLData: Equatable {
    /// See Equatable.==
    public static func ==(lhs: PostgreSQLData, rhs: PostgreSQLData) -> Bool {
        return lhs.format == rhs.format && lhs.type == rhs.type && lhs.data == rhs.data
    }
}
