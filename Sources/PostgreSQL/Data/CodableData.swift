public enum CodableData {
    case string(String)
    case bool(Bool)

    case int(Int)
    case int8(Int8)
    case int16(Int16)
    case int32(Int32)
    case int64(Int64)

    case uint(UInt)
    case uint8(UInt8)
    case uint16(UInt16)
    case uint32(UInt32)
    case uint64(UInt64)

    case float(Float)
    case double(Double)

    case encodable(Encodable)
    case decodable(Decodable)

    case dictionary([String: CodableData])
    case array([CodableData])

    case null
}

extension CodableData: Equatable {
    /// See Equatable.==
    public static func ==(lhs: CodableData, rhs: CodableData) -> Bool {
        switch (lhs, rhs) {
        case (.string(let a), .string(let b)): return a == b
        case (.int(let a), .int(let b)): return a == b
        case (.int8(let a), .int8(let b)): return a == b
        case (.int16(let a), .int16(let b)): return a == b
        case (.int32(let a), .int32(let b)): return a == b
        case (.int64(let a), .int64(let b)): return a == b
        case (.uint(let a), .uint(let b)): return a == b
        case (.uint8(let a), .uint8(let b)): return a == b
        case (.uint16(let a), .uint16(let b)): return a == b
        case (.uint32(let a), .uint32(let b)): return a == b
        case (.uint64(let a), .uint64(let b)): return a == b
        case (.float(let a), .float(let b)): return a == b
        case (.double(let a), .double(let b)): return a == b
        case (.dictionary(let a), .dictionary(let b)): return a == b
        case (.array(let a), .array(let b)): return a == b
        case (.null, .null): return true
        default: return false
        }
    }
}

extension CodableData {
    var array: [CodableData]? {
        switch self {
        case .array(let value): return value
        default: return nil
        }
    }

    var dictionary: [String: CodableData]? {
        switch self {
        case .dictionary(let value): return value
        default: return nil
        }
    }
}

/// Reference wrapper for `PostgreSQLData` being mutated
/// by the PostgreSQL data coders.
final class PartialCodableData {
    /// The partial data.
    var data: CodableData

    /// Creates a new `PartialPostgreSQLData`.
    init(data: CodableData) {
        self.data = data
    }

    /// Sets the `PostgreSQLData` at supplied coding path.
    internal func set(_ data: CodableData, at path: [CodingKey]) {
        guard path.count == 1 else {
            fatalError()
        }
        set(&self.data, to: data, at: path)
    }

    /// Returns the value, if one at from the given path.
    internal func get(at path: [CodingKey]) -> CodableData? {
        var child = data
        for seg in path {
            switch child {
            case .array(let arr):
                guard let index = seg.intValue, arr.count > index else {
                    return nil
                }
                child = arr[index]
            case .dictionary(let dict):
                guard let value = dict[seg.stringValue] else {
                    return nil
                }
                child = value
            default:
                return nil
            }
        }
        return child
    }

    /// Sets the mutable `PostgreSQLData` to supplied data at coding path.
    private func set(_ context: inout CodableData, to value: CodableData, at path: [CodingKey]) {
        guard path.count >= 1 else {
            context = value
            return
        }

        let end = path[0]

        var child: CodableData?
        switch path.count {
        case 1:
            child = value
        case 2...:
            if let index = end.intValue {
                let array = context.array ?? []
                if array.count > index {
                    child = array[index]
                } else {
                    child = CodableData.array([])
                }
                set(&child!, to: value, at: Array(path[1...]))
            } else {
                child = context.dictionary?[end.stringValue] ?? CodableData.dictionary([:])
                set(&child!, to: value, at: Array(path[1...]))
            }
        default: break
        }

        if let index = end.intValue {
            if case .array(var arr) = context {
                if arr.count > index {
                    arr[index] = child ?? .null
                } else {
                    arr.append(child ?? .null)
                }
                context = .array(arr)
            } else if let child = child {
                context = .array([child])
            }
        } else {
            if case .dictionary(var dict) = context {
                dict[end.stringValue] = child
                context = .dictionary(dict)
            } else if let child = child {
                context = .dictionary([
                    end.stringValue: child
                ])
            }
        }
    }
}

/// MARK: Decoding

extension PartialCodableData {
    /// Gets a `nil` from the supplied path or throws a decoding error.
    func decodeNil(at path: [CodingKey]) -> Bool {
        if let value = get(at: path) {
            return value == .null
        } else {
            return true
        }
    }

    /// Gets a `Bool` from the supplied path or throws a decoding error.
    func decodeBool(at path: [CodingKey]) throws -> Bool {
        switch try requireGet(Bool.self, at: path) {
        case .bool(let value): return value
        default: throw DecodingError.typeMismatch(Bool.self, .init(codingPath: path, debugDescription: ""))
        }
    }

    /// Gets a `String` from the supplied path or throws a decoding error.
    func decodeString(at path: [CodingKey]) throws -> String {
        switch try requireGet(String.self, at: path) {
        case .string(let value): return value
        default: throw DecodingError.typeMismatch(String.self, .init(codingPath: path, debugDescription: ""))
        }
    }


    /// Gets a `String` from the supplied path or throws a decoding error.
    func decode<D>(_ type: D.Type = D.self, at path: [CodingKey]) throws -> D where D: Decodable {
        let decoder = _CodableDataDecoder(partialData: self, at: path)
        return try D(from: decoder)
//        switch try requireGet(D.self, at: path) {
//        case .bool(let bool): return bool
//        default: throw DecodingError.typeMismatch(String.self, .init(codingPath: path, debugDescription: ""))
//        }
    }

    /// Gets a `Float` from the supplied path or throws a decoding error.
    func decodeFixedWidthInteger<I>(_ type: I.Type = I.self, at path: [CodingKey]) throws -> I
        where I: FixedWidthInteger
    {
        switch try requireGet(I.self, at: path) {
        case .int(let value): return try safeCast(value, at: path)
        case .int8(let value): return try safeCast(value, at: path)
        case .int16(let value): return try safeCast(value, at: path)
        case .int32(let value): return try safeCast(value, at: path)
        case .int64(let value): return try safeCast(value, at: path)
        case .uint(let value): return try safeCast(value, at: path)
        case .uint8(let value): return try safeCast(value, at: path)
        case .uint16(let value): return try safeCast(value, at: path)
        case .uint32(let value): return try safeCast(value, at: path)
        case .uint64(let value): return try safeCast(value, at: path)
        default: throw DecodingError.typeMismatch(type, .init(codingPath: path, debugDescription: ""))
        }
    }

    /// Gets a `FloatingPoint` from the supplied path or throws a decoding error.
    func decodeFloatingPoint<F>(_ type: F.Type = F.self, at path: [CodingKey]) throws -> F
        where F: BinaryFloatingPoint
    {
        switch try requireGet(F.self, at: path) {
        case .int(let value): return F(value)
        case .int8(let value): return F(value)
        case .int16(let value): return F(value)
        case .int32(let value): return F(value)
        case .int64(let value): return F(value)
        case .uint(let value): return F(value)
        case .uint8(let value): return F(value)
        case .uint16(let value): return F(value)
        case .uint32(let value): return F(value)
        case .uint64(let value): return F(value)
        case .float(let float): return F(float)
        case .double(let double): return F(double)
        default: throw DecodingError.typeMismatch(F.self, .init(codingPath: path, debugDescription: ""))
        }
    }

    /// Gets a value at the supplied path or throws a decoding error.
    func requireGet<T>(_ type: T.Type, at path: [CodingKey]) throws -> CodableData {
        switch get(at: path) {
        case .some(let w): return w
        case .none: throw DecodingError.valueNotFound(T.self, .init(codingPath: path, debugDescription: ""))
        }
    }

    /// Safely casts one `FixedWidthInteger` to another.
    private func safeCast<I, V>(_ value: V, at path: [CodingKey], to type: I.Type = I.self) throws -> I where V: FixedWidthInteger, I: FixedWidthInteger {
        if let existing = value as? I {
            return existing
        }

        guard I.bitWidth >= V.bitWidth else {
            throw DecodingError.typeMismatch(type, .init(codingPath: path, debugDescription: "Bit width too wide: \(I.bitWidth) < \(V.bitWidth)"))
        }
        guard value <= I.max else {
            throw DecodingError.typeMismatch(type, .init(codingPath: path, debugDescription: "Value too large: \(value) > \(I.max)"))
        }
        guard value >= I.min else {
            throw DecodingError.typeMismatch(type, .init(codingPath: path, debugDescription: "Value too small: \(value) < \(I.min)"))
        }
        return I(value)
    }
}
