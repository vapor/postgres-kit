import Foundation

/// Supported `PostgreSQLData` data types.
public enum PostgreSQLData {
    case string(String)
    case data(Data)
    case date(Date)

    case int8(Int8)
    case int16(Int16)
    case int32(Int32)
    case int(Int)

    case uint8(UInt8)
    case uint16(UInt16)
    case uint32(UInt32)
    case uint(UInt)

    case float(Float)
    case double(Double)

    case point(x: Int, y: Int)
    
    case null
}

/// MARK: Polymorphic

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
        case .uint8(let ui): return Int(ui)
        case .uint16(let ui): return Int(ui)
        case .uint32(let ui): return Int(ui)
        case .uint(let ui):
            guard ui < UInt(Int.max) else { return nil }
            return Int(ui)
        case .string(let s): return Int(s)
        default: return nil
        }
    }

    /// Returns bool value, `nil` if not a bool.
    public var bool: Bool? {
        if let int = self.int {
            switch int {
            case 1: return true
            case 0: return false
            default: return nil
            }
        } else if let string = self.string {
            switch string.lowercased() {
            case "t", "true": return true
            case "f", "false": return false
            default: return nil
            }
        } else {
            return nil
        }
    }
}

/// MARK: Equatable

extension PostgreSQLData: Equatable {
    /// See Equatable.==
    public static func ==(lhs: PostgreSQLData, rhs: PostgreSQLData) -> Bool {
        switch (lhs, rhs) {
        case (.string(let a), .string(let b)): return a == b
        case (.data(let a), .data(let b)): return a == b
        case (.date(let a), .date(let b)): return a == b
        case (.int8(let a), .int8(let b)): return a == b
        case (.int16(let a), .int16(let b)): return a == b
        case (.int32(let a), .int32(let b)): return a == b
        case (.int(let a), .int(let b)): return a == b
        case (.uint8(let a), .uint8(let b)): return a == b
        case (.uint16(let a), .uint16(let b)): return a == b
        case (.uint32(let a), .uint32(let b)): return a == b
        case (.uint(let a), .uint(let b)): return a == b
        case (.float(let a), .float(let b)): return a == b
        case (.double(let a), .double(let b)): return a == b
        case (.point(let a), .point(let b)): return a == b
        case (.null, .null): return true
        default: return false
        }
    }


}

/// MARK: Custom String

extension PostgreSQLData: CustomStringConvertible {
    /// See CustomStringConvertible.description
    public var description: String {
        switch self {
        case .string(let val): return "\"\(val)\""
        case .data(let val): return val.hexDebug
        case .date(let val): return val.description
        case .int8(let val): return "\(val) (int8)"
        case .int16(let val): return "\(val) (int16)"
        case .int32(let val): return "\(val) (int32)"
        case .int(let val): return "\(val) (int)"
        case .uint8(let val): return "\(val) (uint8)"
        case .uint16(let val): return "\(val) (uint16)"
        case .uint32(let val): return "\(val) (uint32)"
        case .uint(let val): return "\(val) (uint)"
        case .float(let val): return "\(val) (float)"
        case .double(let val): return "\(val) (double)"
        case .point(let x, let y): return "(\(x), \(y))"
        case .null: return "null"
        }
    }
}
