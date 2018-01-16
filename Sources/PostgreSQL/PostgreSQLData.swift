/// Supported `PostgreSQLData` data types.
public enum PostgreSQLData {
    case character(Character)
    case string(String)
    
    case bool(Bool)

    case int8(Int8)
    case int16(Int16)
    case int32(Int32)
    case int(Int)

    case uint8(UInt8)
    case uint16(UInt16)
    case uint32(UInt32)
    case uint(UInt)
    
    case null
}

extension PostgreSQLData {
    /// Returns string value, `nil` if not a string.
    public var string: String? {
        switch self {
        case .string(let s): return s
        default: return nil
        }
    }

    /// Returns int value, `nil` if not an int.
    public var int: Int? {
        switch self {
        case .int8(let i): return Int(i)
        case .int16(let i): return Int(i)
        case .int32(let i): return Int(i)
        case .int(let i): return i
        case .string(let s): return Int(s)
        default: return nil
        }
    }
}
