import Foundation

/// Supported `PostgreSQLData` data types.
public struct PostgreSQLData: Equatable {
    /// The data's type.
    public var type: PostgreSQLDataType

    enum Storage: Equatable {
        case text(String)
        case binary(Data)
        case null
    }
    
    
    /// The data's format.
    let storage: Storage

    /// If `true`, this data is null.
    public var isNull: Bool {
        switch storage {
        case .null: return true
        default: return false
        }
    }

    public var binary: Data? {
        switch storage {
        case .binary(let data): return data
        default: return nil
        }
    }
    
    public var text: String? {
        switch storage {
        case .text(let string): return string
        default: return nil
        }
    }

    public init(_ type: PostgreSQLDataType, binary: Data) {
        self.type = type
        self.storage = .binary(binary)
    }
    
    public init(_ type: PostgreSQLDataType, text: String) {
        self.type = type
        self.storage = .text(text)
    }
    
    public init(null: PostgreSQLDataType) {
        self.type = null
        self.storage = .null
    }
}

extension PostgreSQLData: CustomStringConvertible {
    /// See `CustomStringConvertible`.
    public var description: String {
        switch storage {
        case .binary(let data): return type.description + " 0x\(data.hexEncodedString())"
        case .text(let string): return type.description + " " + string
        case .null:  return type.description + " <null>"
        }
    }
}
