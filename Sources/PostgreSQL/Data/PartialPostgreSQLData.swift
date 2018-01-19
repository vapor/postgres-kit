import COperatingSystem
import Foundation

/// Reference wrapper for `PostgreSQLData` being mutated
/// by the PostgreSQL data coders.
final class PartialPostgreSQLData {
    /// The partial data.
    var data: [String: PostgreSQLData]

    /// Creates a new `PartialPostgreSQLData`.
    init(data: [String: PostgreSQLData]) {
        self.data = data
    }

    /// Sets the `PostgreSQLData` at supplied coding path.
    func set(_ data: PostgreSQLData, at path: [CodingKey]) {
        guard path.count == 1 else {
            fatalError()
        }
        self.data[path[0].stringValue] = data
        // set(&self.data, to: data, at: path)
    }

    /// Returns the value, if one at from the given path.
    func get(at path: [CodingKey]) -> PostgreSQLData? {
        guard path.count == 1 else {
            fatalError()
        }
        return self.data[path[0].stringValue]
//        var child = data
//        for seg in path {
//            switch child {
//            case .array(let arr):
//                guard let index = seg.intValue, arr.count > index else {
//                    return nil
//                }
//                child = arr[index]
//            case .dictionary(let dict):
//                guard let value = dict[seg.stringValue] else {
//                    return nil
//                }
//                child = value
//            default:
//                return nil
//            }
//        }
//        return child
    }

//    /// Sets the mutable `PostgreSQLData` to supplied data at coding path.
//    private func set(_ context: inout PostgreSQLData, to value: PostgreSQLData, at path: [CodingKey]) {
//        guard path.count >= 1 else {
//            context = value
//            return
//        }
//
//        let end = path[0]
//
//        var child: PostgreSQLData?
//        switch path.count {
//        case 1:
//            child = value
//        case 2...:
//            if let index = end.intValue {
//                let array = context.array ?? []
//                if array.count > index {
//                    child = array[index]
//                } else {
//                    child = PostgreSQLData.array([])
//                }
//                set(&child!, to: value, at: Array(path[1...]))
//            } else {
//                child = context.dictionary?[end.stringValue] ?? PostgreSQLData.dictionary([:])
//                set(&child!, to: value, at: Array(path[1...]))
//            }
//        default: break
//        }
//
//        if let index = end.intValue {
//            if case .array(var arr) = context {
//                if arr.count > index {
//                    arr[index] = child ?? .null
//                } else {
//                    arr.append(child ?? .null)
//                }
//                context = .array(arr)
//            } else if let child = child {
//                context = .array([child])
//            }
//        } else {
//            if case .dictionary(var dict) = context {
//                dict[end.stringValue] = child
//                context = .dictionary(dict)
//            } else if let child = child {
//                context = .dictionary([
//                    end.stringValue: child
//                ])
//            }
//        }
//    }
}


/// MARK: Encoding Convenience

extension FixedWidthInteger {
    /// Big-endian bytes for this integer.
    fileprivate var data: Data {
        var bytes = [UInt8](repeating: 0, count: Self.bitWidth / 8)
        var intNetwork = bigEndian
        memcpy(&bytes, &intNetwork, bytes.count)
        return Data(bytes)
    }
}

extension FloatingPoint {
    /// Big-endian bytes for this floating-point number.
    fileprivate var data: Data {
        var bytes = [UInt8](repeating: 0, count: MemoryLayout<Self>.size)
        var copy = self
        memcpy(&bytes, &copy, bytes.count)
        return Data(bytes.reversed())
    }
}

extension Data {
    /// Converts this data to a floating-point number.
    fileprivate func makeFloatingPoint<F>(_ type: F.Type = F.self) -> F where F: FloatingPoint {
        return Data(reversed()).unsafeCast()
    }

    /// Converts this data to a fixed-width integer.
    fileprivate func makeFixedWidthInteger<I>(_ type: I.Type = I.self) -> I where I: FixedWidthInteger {
        return unsafeCast(to: I.self).bigEndian
    }

    fileprivate func unsafeCast<T>(to type: T.Type = T.self) -> T {
        return withUnsafeBytes { (pointer: UnsafePointer<T>) -> T in
            return pointer.pointee
        }
    }

    /// Convert the row's data into a string, throwing if invalid encoding.
    fileprivate func makeString(encoding: String.Encoding = .utf8) throws -> String {
        guard let string = String(data: self, encoding: encoding) else {
            throw PostgreSQLError(identifier: "utf8String", reason: "Unexpected non-UTF8 string.")
        }

        return string
    }
}

extension PartialPostgreSQLData {
    /// Sets a generic fixed width integer to the supplied path.
    func setFixedWidthInteger<U>(_ value: U, at path: [CodingKey]) throws
        where U: FixedWidthInteger
    {
//        switch U.bitWidth {
//        case 8: try set(.int8(safeCast(value, at: path)), at: path)
//        case 16: try set(.int16(safeCast(value, at: path)), at: path)
//        case 32: try set(.int32(safeCast(value, at: path)), at: path)
//        case 64: try set(.int64(safeCast(value, at: path)), at: path)
//        default: throw DecodingError.typeMismatch(U.self, .init(codingPath: path, debugDescription: "Integer bit width not supported: \(U.bitWidth)"))
//        }
        let type: PostgreSQLDataType
        switch U.bitWidth {
        case 8: type = .char
        case 16: type = .int2
        case 32: type = .int4
        case 64: type = .int8
        default: throw DecodingError.typeMismatch(U.self, .init(codingPath: path, debugDescription: "Integer bit width not supported: \(U.bitWidth)"))
        }
        set(.init(type: type, data: value.data), at: path)
    }

    /// Sets an encodable value at the supplied path.
    func setEncodable<E>(_ value: E, at path: [CodingKey]) throws where E: Encodable {
        if let value = value as? PostgreSQLDataCustomConvertible {
            try set(value.convertToPostgreSQLData(), at: path)
        } else {
            fatalError()
//            let encoder = _PostgreSQLDataEncoder(partialData: self, at: path)
//            try value.encode(to: encoder)
        }
    }

    func encodeNil(at path: [CodingKey]) {
        // implement
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

    func decodeNil(at path: [CodingKey]) -> Bool {
        return get(at: path) == nil
    }

    /// Gets a decodable value at the supplied path.
    func decode<D>(_ value: D.Type = D.self, at path: [CodingKey]) throws -> D
        where D: Decodable
    {
        if let convertible = D.self as? PostgreSQLDataCustomConvertible.Type {
            let data = try requireGet(D.self, at: path)
            return try convertible.convertFromPostgreSQLData(data) as! D
        } else {
            fatalError()
//            let decoder = _PostgreSQLDataDecoder(partialData: self, at: path)
//            return try D(from: decoder)
        }
    }

    /// Gets a `Float` from the supplied path or throws a decoding error.
    func decodeFixedWidthInteger<I>(_ type: I.Type = I.self, at path: [CodingKey]) throws -> I
        where I: FixedWidthInteger
    {
        let data = try requireGet(I.self, at: path)
        guard let value = data.data else {
            fatalError()
        }
        switch data.type {
        case .char: return try safeCast(value.makeFixedWidthInteger(Int8.self), at: path)
        case .int2: return try safeCast(value.makeFixedWidthInteger(Int16.self), at: path)
        case .int4: return try safeCast(value.makeFixedWidthInteger(Int32.self), at: path)
        case .int8: return try safeCast(value.makeFixedWidthInteger(Int64.self), at: path)
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
    func decodeFloatingPoint<F>(_ type: F.Type = F.self, at path: [CodingKey]) throws -> F
        where F: BinaryFloatingPoint
    {
        let data = try requireGet(F.self, at: path)
        guard let value = data.data else {
            fatalError()
        }
        switch data.type {
        case .char: return F(value.makeFixedWidthInteger(Int8.self))
        case .int2: return F(value.makeFixedWidthInteger(Int16.self))
        case .int4: return F(value.makeFixedWidthInteger(Int32.self))
        case .int8: return F(value.makeFixedWidthInteger(Int64.self))
        case .float4: return F(value.makeFloatingPoint(Float.self))
        case .float8: return F(value.makeFloatingPoint(Double.self))
        default: throw DecodingError.typeMismatch(F.self, .init(codingPath: path, debugDescription: ""))
        }
    }

    /// Gets a `Bool` from the supplied path or throws a decoding error.
    func decodeBool(at path: [CodingKey]) throws -> Bool {
        let data = try requireGet(String.self, at: path)
        guard let value = data.data else {
            fatalError()
        }
        switch data.type {
        case .char: return value.makeFixedWidthInteger(Int8.self) == 1
        default: throw DecodingError.typeMismatch(Bool.self, .init(codingPath: path, debugDescription: ""))
        }
    }
}

extension PostgreSQLData {
    /// Gets a `String` from the supplied path or throws a decoding error.
    public func decodeString() throws -> String {
        guard let value = self.data else {
            throw PostgreSQLError(identifier: "data", reason: "Could not decode String from `null` data.")
        }
        switch type {
        case .text, .name: return String(data: value, encoding: .utf8) !! "Non-utf8"
        default: throw PostgreSQLError(identifier: "data", reason: "Could not decode String from data type: \(type)")
        }
    }

    /// Gets a `String` from the supplied path or throws a decoding error.
    public func decode<T>(_ type: T.Type) throws -> T where T: PostgreSQLDataCustomConvertible {
        return try T.convertFromPostgreSQLData(self)
    }
}

extension String: PostgreSQLDataCustomConvertible {
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> String {
        guard let value = data.data else {
            throw PostgreSQLError(identifier: "data", reason: "Could not decode String from `null` data.")
        }
        switch data.format {
        case .text: return String(data: value, encoding: .utf8) !! "Non-utf8"
        case .binary:
            switch data.type {
            case .text, .name: return String(data: value, encoding: .utf8) !! "Non-utf8"
            default: throw PostgreSQLError(identifier: "data", reason: "Could not decode String from data type: \(data.type)")
            }
        }
    }

    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return PostgreSQLData(type: .text, format: .binary, data: Data(utf8))
    }
}

extension FixedWidthInteger {
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        guard let value = data.data else {
            throw PostgreSQLError(identifier: "data", reason: "Could not decode String from `null` data.")
        }
        switch data.format {
        case .binary:
            switch data.type {
            case .char: return try safeCast(value.makeFixedWidthInteger(Int8.self))
            case .int2: return try safeCast(value.makeFixedWidthInteger(Int16.self))
            case .int4: return try safeCast(value.makeFixedWidthInteger(Int32.self))
            case .int8: return try safeCast(value.makeFixedWidthInteger(Int64.self))
            default: throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: ""))
            }
        case .text:
            guard let converted = try Self(data.decode(String.self)) else {
                fatalError()
            }
            return converted
        }
    }

    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        let type: PostgreSQLDataType
        switch Self.bitWidth {
        case 8: type = .char
        case 16: type = .int2
        case 32: type = .int4
        case 64: type = .int8
        default: throw DecodingError.typeMismatch(Self.self, .init(codingPath: [], debugDescription: "Integer bit width not supported: \(Self.bitWidth)"))
        }
        return PostgreSQLData(type: type, format: .binary, data: self.data)
    }


    /// Safely casts one `FixedWidthInteger` to another.
    private static func safeCast<I, V>(_ value: V, to type: I.Type = I.self) throws -> I where V: FixedWidthInteger, I: FixedWidthInteger {
        if let existing = value as? I {
            return existing
        }

        guard I.bitWidth >= V.bitWidth else {
            throw DecodingError.typeMismatch(type, .init(codingPath: [], debugDescription: "Bit width too wide: \(I.bitWidth) < \(V.bitWidth)"))
        }
        guard value <= I.max else {
            throw DecodingError.typeMismatch(type, .init(codingPath: [], debugDescription: "Value too large: \(value) > \(I.max)"))
        }
        guard value >= I.min else {
            throw DecodingError.typeMismatch(type, .init(codingPath: [], debugDescription: "Value too small: \(value) < \(I.min)"))
        }
        return I(value)
    }
}

extension Int: PostgreSQLDataCustomConvertible {}
extension Int8: PostgreSQLDataCustomConvertible {}
extension Int16: PostgreSQLDataCustomConvertible {}
extension Int32: PostgreSQLDataCustomConvertible {}
extension Int64: PostgreSQLDataCustomConvertible {}

extension UInt: PostgreSQLDataCustomConvertible {}
extension UInt8: PostgreSQLDataCustomConvertible {}
extension UInt16: PostgreSQLDataCustomConvertible {}
extension UInt32: PostgreSQLDataCustomConvertible {}
extension UInt64: PostgreSQLDataCustomConvertible {}
