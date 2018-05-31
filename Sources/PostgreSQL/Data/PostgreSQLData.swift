import Foundation

/// Supported `PostgreSQLData` data types.
public struct PostgreSQLData {
    /// The data's type.
    public var type: PostgreSQLDataType

    /// The data's format.
    public var format: PostgreSQLFormatCode

    /// If `true`, this data is null.
    public var isNull: Bool {
        return data == nil
    }

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
        if let data = data {
            switch type {
            case .text, .varchar: return "\(type) (\(format)) \(String(data: data, encoding: .ascii) ?? "<non-ascii>"))"
            default: return "\(type) (\(format)) 0x\(data.hexEncodedString())"
            }
            
        } else {
            return "\(type) (\(format)) <null>"
        }
    }
}

/// MARK: Equatable

extension PostgreSQLData: Equatable {
    /// See Equatable.==
    public static func ==(lhs: PostgreSQLData, rhs: PostgreSQLData) -> Bool {
        return lhs.format == rhs.format && lhs.type == rhs.type && lhs.data == rhs.data
    }
}
