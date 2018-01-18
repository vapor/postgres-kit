/// Reference wrapper for `PostgreSQLData` being mutated
/// by the PostgreSQL data coders.
final class PartialPostgreSQLData {
    /// The partial data.
    var data: PostgreSQLData

    /// Creates a new `PartialPostgreSQLData`.
    init(data: PostgreSQLData) {
        self.data = data
    }

    /// Sets the `PostgreSQLData` at supplied coding path.
    func set(_ data: PostgreSQLData, at path: [CodingKey]) {
        set(&self.data, to: data, at: path)
    }

    /// Returns the value, if one at from the given path.
    func get(at path: [CodingKey]) -> PostgreSQLData? {
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
    private func set(_ context: inout PostgreSQLData, to value: PostgreSQLData, at path: [CodingKey]) {
        guard path.count >= 1 else {
            context = value
            return
        }

        let end = path[0]

        var child: PostgreSQLData?
        switch path.count {
        case 1:
            child = value
        case 2...:
            if let index = end.intValue {
                let array = context.array ?? []
                if array.count > index {
                    child = array[index]
                } else {
                    child = PostgreSQLData.array([])
                }
                set(&child!, to: value, at: Array(path[1...]))
            } else {
                child = context.dictionary?[end.stringValue] ?? PostgreSQLData.dictionary([:])
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


/// MARK: Encoding Convenience

extension PartialPostgreSQLData {
    /// Sets a generic fixed width integer to the supplied path.
    func setFixedWidthInteger<U>(_ value: U, at path: [CodingKey]) throws
        where U: FixedWidthInteger
    {
        switch U.bitWidth {
        case 8: try set(.int8(safeCast(value, at: path)), at: path)
        case 16: try set(.int16(safeCast(value, at: path)), at: path)
        case 32: try set(.int32(safeCast(value, at: path)), at: path)
        case 64: try set(.int64(safeCast(value, at: path)), at: path)
        default: throw DecodingError.typeMismatch(U.self, .init(codingPath: path, debugDescription: "Integer bit width not supported: \(U.bitWidth)"))
        }
    }
}

/// MARK: Decoding Convenience

extension PartialPostgreSQLData {
    /// Gets a value at the supplied path or throws a decoding error.
    func requireGet<T>(_ type: T.Type, at path: [CodingKey]) throws -> PostgreSQLData {
        switch get(at: path) {
        case .some(let w): return w
        case .none: throw DecodingError.valueNotFound(T.self, .init(codingPath: path, debugDescription: ""))
        }
    }

    /// Gets a `Float` from the supplied path or throws a decoding error.
    func requireFixedWidthItenger<I>(_ type: I.Type = I.self, at path: [CodingKey]) throws -> I
        where I: FixedWidthInteger
    {
        switch try requireGet(I.self, at: path) {
        case .int8(let value): return try safeCast(value, at: path)
        case .int16(let value): return try safeCast(value, at: path)
        case .int32(let value): return try safeCast(value, at: path)
        case .int64(let value): return try safeCast(value, at: path)
        default: throw DecodingError.typeMismatch(type, .init(codingPath: path, debugDescription: ""))
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

    /// Gets a `FloatingPoint` from the supplied path or throws a decoding error.
    func requireFloatingPoint<F>(_ type: F.Type = F.self, at path: [CodingKey]) throws -> F
        where F: BinaryFloatingPoint
    {
        switch try requireGet(F.self, at: path) {
        case .int8(let value): return F(value)
        case .int16(let value): return F(value)
        case .int32(let value): return F(value)
        case .int64(let value): return F(value)
        case .float(let value): return F(value)
        case .double(let value): return F(value)
        default: throw DecodingError.typeMismatch(F.self, .init(codingPath: path, debugDescription: ""))
        }
    }

    /// Gets a `String` from the supplied path or throws a decoding error.
    func requireString(at path: [CodingKey]) throws -> String {
        switch try requireGet(String.self, at: path) {
        case .string(let value): return value
        default: throw DecodingError.typeMismatch(String.self, .init(codingPath: path, debugDescription: ""))
        }
    }

    /// Gets a `Bool` from the supplied path or throws a decoding error.
    func requireBool(at path: [CodingKey]) throws -> Bool {
        switch try requireGet(Bool.self, at: path) {
        case .bool(let value): return value
        default: throw DecodingError.typeMismatch(Bool.self, .init(codingPath: path, debugDescription: ""))
        }
    }
}
