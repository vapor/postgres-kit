import Foundation

/// Supported `PostgreSQLData` data types.
public enum PostgreSQLData {
    case string(String)
    case data(Data)
    case date(Date)

    case bool(Bool)

    case int8(Int8)
    case int16(Int16)
    case int32(Int32)
    case int64(Int64)

    case float(Float)
    case double(Double)

    case point(x: Double, y: Double)

    case uuid(UUID)

    case dictionary([String: PostgreSQLData])
    case array([PostgreSQLData])
    
    case null
}

extension PostgreSQLData: Codable {
    /// See `Decodable.init(from:)`
    public init(from decoder: Decoder) throws {
        if let dict = try? [String: PostgreSQLData](from: decoder) {
            self = .dictionary(dict)
        } else if let arr = try? [PostgreSQLData](from: decoder) {
            self = .array(arr)
        } else if let double = try? Double(from: decoder) {
            self = .double(double)
        } else if let int = try? Int(from: decoder) {
            self = .int64(Int64(int))
        } else if let bool = try? Bool(from: decoder) {
            self = .bool(bool)
        } else if let string = try? String(from: decoder) {
            self = .string(string)
        } else {
            throw PostgreSQLError(identifier: "decode", reason: "Cannot decode PostgreSQL data")
        }
    }

    /// See `Encodable.encode`
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .string(let value): try value.encode(to: encoder)
        case .data(let value): try value.encode(to: encoder)
        case .date(let value): try value.encode(to: encoder)
        case .bool(let value): try value.encode(to: encoder)
        case .int8(let value): try value.encode(to: encoder)
        case .int16(let value): try value.encode(to: encoder)
        case .int32(let value): try value.encode(to: encoder)
        case .int64(let value): try value.encode(to: encoder)
        case .float(let value): try value.encode(to: encoder)
        case .double(let value): try value.encode(to: encoder)
        case .uuid(let value): try value.encode(to: encoder)
        case .array(let value): try value.encode(to: encoder)
        case .dictionary(let value): try value.encode(to: encoder)
        case .point: throw PostgreSQLError(identifier: "encode", reason: "Cannot encode point: \(self)")
        case .null:
            var single = encoder.singleValueContainer()
            try single.encodeNil()
        }
    }
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
        case .int64(let i):
            guard i <= Int64(Int.max) else { return nil }
            return Int(i)
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

    /// Returns dictionary value, `nil` if not a dictionary.
    public var dictionary: [String: PostgreSQLData]? {
        switch self {
        case .dictionary(let d): return d
        default: return nil
        }
    }

    /// Returns array value, `nil` if not an array.
    public var array: [PostgreSQLData]? {
        switch self {
        case .array(let a): return a
        default: return nil
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
        case (.int64(let a), .int64(let b)): return a == b
        case (.float(let a), .float(let b)): return a == b
        case (.double(let a), .double(let b)): return a == b
        case (.point(let a), .point(let b)): return a == b
        case (.dictionary(let a), .dictionary(let b)): return a == b
        case (.array(let a), .array(let b)): return a == b
        case (.uuid(let a), .uuid(let b)): return a == b
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
        case .int64(let val): return "\(val) (int64)"
        case .float(let val): return "\(val) (float)"
        case .double(let val): return "\(val) (double)"
        case .point(let x, let y): return "(\(x), \(y))"
        case .bool(let bool): return bool.description
        case .dictionary(let d): return d.description
        case .array(let a): return a.description
        case .uuid(let uuid): return "\(uuid) (uuid)"
        case .null: return "null"
        }
    }
}
