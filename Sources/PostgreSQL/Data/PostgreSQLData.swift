/// Supported `PostgreSQLData` data types.
public struct PostgreSQLData: Equatable {
    /// `NULL` data.
    public static let null: PostgreSQLData = PostgreSQLData(type: .null, storage: .null)
    
    /// The data's type.
    public var type: PostgreSQLDataFormat

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
    internal init(type: PostgreSQLDataFormat, storage: Storage) {
        self.type = type
        self.storage = storage
    }

    /// Creates a new binary-formatted `PostgreSQLData`.
    ///
    /// - parameters:
    ///     - type: Data type.
    ///     - binary: Binary data blob.
    public init(_ type: PostgreSQLDataFormat, binary: Data) {
        self.type = type
        self.storage = .binary(binary)
    }
    
    
    /// Creates a new text-formatted `PostgreSQLData`.
    ///
    /// - parameters:
    ///     - type: Data type.
    ///     - text: Text string.
    public init(_ type: PostgreSQLDataFormat, text: String) {
        self.type = type
        self.storage = .text(text)
    }
}

extension PostgreSQLData: CustomStringConvertible {
    /// See `CustomStringConvertible`.
    public var description: String {
        let readable: String
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
            case .int8: override = data.as(Int64.self, default: 0).bigEndian.description
            case .int4: override = data.as(Int32.self, default: 0).bigEndian.description
            case .int2: override = data.as(Int16.self, default: 0).bigEndian.description
            case .uuid: override = UUID.init(uuid: data.as(uuid_t.self, default: (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))).description
            default: break
            }
            
            readable = override ?? "0x" + data.hexEncodedString()
        case .text(let string): readable = "\"" + string + "\""
        case .null:  return "null"
        }
        return readable + " (" + type.description + ")"
    }
}
