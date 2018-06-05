/// Supported `PostgreSQLData` data types.
public struct PostgreSQLData: Equatable, Encodable {
    /// `NULL` data.
    public static let null: PostgreSQLData = PostgreSQLData(type: .null, storage: .null)
    
    /// The data's type.
    public var type: PostgreSQLDataType

    /// Internal storage type.
    enum Storage: Equatable {
        case text(String)
        case binary(Data)
        case null
    }
    
    /// The data's format.
    let storage: Storage

    /// Binary-formatted `Data`. `nil` if this data is null or not binary formatted.
    public var binary: Data? {
        switch storage {
        case .binary(let data): return data
        default: return nil
        }
    }
    
    /// Text-formatted `String`. `nil` if this data is null or not text formatted.
    public var text: String? {
        switch storage {
        case .text(let string): return string
        default: return nil
        }
    }
    
    /// If `true`, this data is null.
    public var isNull: Bool {
        switch storage {
        case .null: return true
        default: return false
        }
    }
    
    /// Internal init.
    internal init(type: PostgreSQLDataType, storage: Storage) {
        self.type = type
        self.storage = storage
    }

    /// Creates a new binary-formatted `PostgreSQLData`.
    ///
    /// - parameters:
    ///     - type: Data type.
    ///     - binary: Binary data blob.
    public init(_ type: PostgreSQLDataType, binary: Data) {
        self.type = type
        self.storage = .binary(binary)
    }
    
    
    /// Creates a new text-formatted `PostgreSQLData`.
    ///
    /// - parameters:
    ///     - type: Data type.
    ///     - text: Text string.
    public init(_ type: PostgreSQLDataType, text: String) {
        self.type = type
        self.storage = .text(text)
    }
    
    /// See `Decodable`.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(.void, binary: container.decode(Data.self))
    }
    
    /// See `Encodable`.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch storage {
        case .binary(let binary): try container.encode(binary)
        case .text(let text): try container.encode(text)
        case .null: try container.encodeNil()
        }
    }
}

extension PostgreSQLData: CustomStringConvertible {
    /// See `CustomStringConvertible`.
    public var description: String {
        switch storage {
        case .binary(let data):
            var override: String?
            switch type {
            case .json, .text, .varchar:
                if let utf8 = String(data: data, encoding: .utf8) {
                    override = "\"" + utf8 + "\""
                }
            case .jsonb:
                if let utf8 = String(data: data.dropFirst(), encoding: .utf8) {
                    override = utf8
                }
            default: break
            }
            
            let readable = override ?? "0x" + data.hexEncodedString()
            return readable + ":" + type.description
        case .text(let string): return "\"" + string + "\":" + type.description
        case .null:  return "null"
        }
    }
}
