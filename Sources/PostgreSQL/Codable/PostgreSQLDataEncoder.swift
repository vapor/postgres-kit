/// Converts `Encodable` objects to `PostgreSQLData`.
///
///     let data = try PostgreSQLDataEncoder().encode("hello")
///     print(data) // PostgreSQLData
///
public struct PostgreSQLDataEncoder {
    /// Creates a new `PostgreSQLDataEncoder`.
    public init() { }

    /// Encodes the supplied `Encodable` object to `PostgreSQLData`.
    ///
    ///     let data = try PostgreSQLDataEncoder().encode("hello")
    ///     print(data) // PostgreSQLData
    ///
    /// - parameters:
    ///     - encodable: `Encodable` object to encode.
    /// - returns: Encoded `PostgreSQLData`.
    public func encode(_ encodable: Encodable) throws -> PostgreSQLData {
        if let convertible = encodable as? PostgreSQLDataConvertible {
            return try convertible.convertToPostgreSQLData()
        } else {
            // nested encode
            print("nesting for: \(type(of: encodable))")
            let any = try CodableDataEncoder().encode(encodable)
            print(any)
            switch any {
            case .keyed, .unkeyed:
                let json = try JSONEncoder().encode(CodableDataEncoder().encode(encodable))
                return .init(.jsonb, binary: [0x01] + json)
            case .encodable(let encodable): return try encode(encodable)
            case .string(let value): return try value.convertToPostgreSQLData()
            case .int(let value): return .init(.int8, binary: value.bigEndian.data)
            case .int8(let value): return .init(.char, binary: value.bigEndian.data)
            case .int16(let value): return .init(.int2, binary: value.bigEndian.data)
            case .int32(let value): return .init(.int4, binary: value.bigEndian.data)
            case .int64(let value): return .init(.int8, binary: value.bigEndian.data)
            case .uint(let value): return .init(.int8, binary: value.bigEndian.data)
            case .uint8(let value): return .init(.char, binary: value.bigEndian.data)
            case .uint16(let value): return .init(.int2, binary: value.bigEndian.data)
            case .uint32(let value): return .init(.int4, binary: value.bigEndian.data)
            case .uint64(let value): return .init(.int8, binary: value.bigEndian.data)
            case .double(let value): return .init(.float8, binary: .init(value.data.reversed()))
            case .float(let value): return .init(.float4, binary: .init(value.data.reversed()))
            case .null: return .init(null: .null)
            default: throw PostgreSQLError(identifier: "dataEncoder", reason: "Unsupported data type: \(any).")
            }
        }
    }
}

// MARK: Private

public final class CodableDataEncoder {
    public func encode(_ encodable: Encodable) throws -> CodableData {
        let context = _CodableDataContext()
        let encoder = _CodableDataEncoder(context: context, codingPath: [])
        try encodable.encode(to: encoder)
        return context.data
    }
}

public final class CodableDataDecoder {
    public func decode<D>(_ decodable: D.Type, from data: CodableData) throws -> D where D: Decodable {
        let context = _CodableDataContext()
        context.data = data
        let decoder = _CodableDataDecoder(context: context, codingPath: [])
        return D.init(from: decoder)
    }
}

/// Strong type wrapper around type-erased `Encodable` protocol.
public enum CodableData: Encodable {
    /// Unkeyed `Encodable` objects. Potentially nested.
    case unkeyed([CodableData])
    
    /// Keyed `Encodable` objects. Potentially nested.
    case keyed([String: CodableData])
    
    /// `Bool`.
    case bool(Bool)
    
    /// `String`.
    case string(String)
    
    /// `Double`.
    case double(Double)
    
    /// `Float`.
    case float(Float)
    
    /// `Int`.
    case int(Int)
    
    /// `Int8`.
    case int8(Int8)
    
    /// `Int16`.
    case int16(Int16)
    
    /// `Int32`.
    case int32(Int32)
    
    /// `Int64`.
    case int64(Int64)
    
    /// `UInt`.
    case uint(UInt)
    
    /// `UInt8`.
    case uint8(UInt8)
    
    /// `UInt16`.
    case uint16(UInt16)
    
    /// `UInt32`.
    case uint32(UInt32)
    
    /// `UInt64`.
    case uint64(UInt64)
    
    /// Single `Encodable` object.
    case encodable(Encodable)
    
    /// Nil value.
    case null
    
    public var unwrapped: Encodable? {
        switch self {
        case .keyed(let keyed): return keyed
        case .unkeyed(let unkeyed): return unkeyed
        case .bool(let value): return value
        case .string(let value): return value
        case .double(let value): return value
        case .float(let value): return value
        case .int(let value): return value
        case .int8(let value): return value
        case .int16(let value): return value
        case .int32(let value): return value
        case .int64(let value): return value
        case .uint(let value): return value
        case .uint8(let value): return value
        case .uint16(let value): return value
        case .uint32(let value): return value
        case .uint64(let value): return value
        case .encodable(let value): return value
        case .null: return nil
        }
    }
    
    /// See `Encodable`.
    public func encode(to encoder: Encoder) throws {
        if let encodable = unwrapped {
            try encodable.encode(to: encoder)
        } else {
            var single = encoder.singleValueContainer()
            try single.encodeNil()
        }
    }
}

/// Reference-based encoder context.
private final class _CodableDataContext {
    /// Encoded data.
    var data: CodableData
    
    /// Fetches the `CodableData` at the supplied path.
    func get(at codingPath: [CodingKey]) -> CodableData {
        var current = data
        for path in codingPath {
            switch current {
            case .keyed(let keyed): current = keyed[path.stringValue] ?? .null
            case .unkeyed(let unkeyed):
                // not an array path
                guard let index = path.intValue, unkeyed.count > index else {
                    return .null
                }
                current = unkeyed[index]
            case .null: return .null
            default:
                // there are additional paths, but we've hit a single object
                return .null
            }
        }
        return current
    }
    
    /// Sets a new `CodableData` at the supplied path.
    func set(_ codingPath: [CodingKey], to new: CodableData) {
        data = set(data, at: codingPath, to: new)
    }
    
    private func set<C>(_ value: CodableData, at codingPath: C, to new: CodableData) -> CodableData where C: Collection, C.Element == CodingKey {
        switch codingPath.count {
        case 0: return new
        default:
            let path = codingPath[codingPath.startIndex]
            switch value {
            case .keyed(var keyed):
                // update the existing dictionary
                keyed[path.stringValue] = set(keyed[path.stringValue] ?? .null, at: codingPath.dropFirst(), to: new)
                return .keyed(keyed)
            case .unkeyed(var unkeyed):
                // update the existing spot
                unkeyed[path.intValue ?? 0] = set(unkeyed[path.intValue ?? 0], at: codingPath.dropFirst(), to: new)
                return .unkeyed(unkeyed)
            default:
                // create a new dictionary
                return .keyed([
                    path.stringValue: set(.null, at: codingPath.dropFirst(), to: new)
                ])
            }
        }
    }
    
    
    /// Creates a new `AnyEncoderContext`.
    init() {
        data = .null
    }
}

/// Private `Encoder` powering `AnyEncoder`.
private struct _CodableDataEncoder: Encoder {
    /// See `Encoder`.
    let codingPath: [CodingKey]
    
    /// See `Encoder`.
    let userInfo: [CodingUserInfoKey: Any] = [:]
    
    /// Reference-based encoder context.
    let context: _CodableDataContext
    
    /// Creates a new `_AnyEncoder`.
    init(context: _CodableDataContext, codingPath: [CodingKey]) {
        self.context = context
        self.codingPath = codingPath
    }
    
    /// See `Encoder`.
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return .init(_CodableDataKeyedEncoder(context: context, codingPath: codingPath))
    }
    
    /// See `Encoder`.
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("Unkeyed encoding container not supported.")
    }
    
    /// See `Encoder`.
    func singleValueContainer() -> SingleValueEncodingContainer {
        return _CodableDataSingleValueEncoder(context: context, codingPath: codingPath)
    }
}

/// Private `KeyedEncodingContainerProtocol` powering `CodableDataEncoder`.
private struct _CodableDataKeyedEncoder<Key>: KeyedEncodingContainerProtocol where Key: CodingKey {
    /// Reference-based encoder context.
    let context: _CodableDataContext
    
    /// See `KeyedEncodingContainerProtocol`.
    let codingPath: [CodingKey]
    
    /// Creates a new `_CodableDataKeyedEncoder`.
    init(context: _CodableDataContext, codingPath: [CodingKey]) {
        self.context = context
        self.codingPath = codingPath
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encodeNil(forKey key: Key) throws {
        fatalError()
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        context.set(codingPath + [key], to: .bool(value))
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encode(_ value: String, forKey key: Key) throws {
        context.set(codingPath + [key], to: .string(value))
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encode(_ value: Double, forKey key: Key) throws {
        context.set(codingPath + [key], to: .double(value))
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encode(_ value: Float, forKey key: Key) throws {
        context.set(codingPath + [key], to: .float(value))
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encode(_ value: Int, forKey key: Key) throws {
        context.set(codingPath + [key], to: .int(value))
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        context.set(codingPath + [key], to: .int8(value))
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        context.set(codingPath + [key], to: .int16(value))
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        context.set(codingPath + [key], to: .int32(value))
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        context.set(codingPath + [key], to: .int64(value))
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        context.set(codingPath + [key], to: .uint(value))
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        context.set(codingPath + [key], to: .uint8(value))
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        context.set(codingPath + [key], to: .uint16(value))
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        context.set(codingPath + [key], to: .uint32(value))
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        context.set(codingPath + [key], to: .uint64(value))
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        context.set(codingPath + [key], to: .encodable(value))
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encodeIfPresent(_ value: Bool?, forKey key: Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            context.set(codingPath + [key], to: .null)
        }
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encodeIfPresent(_ value: String?, forKey key: Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            context.set(codingPath + [key], to: .null)
        }
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encodeIfPresent(_ value: Double?, forKey key: Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            context.set(codingPath + [key], to: .null)
        }
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encodeIfPresent(_ value: Float?, forKey key: Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            context.set(codingPath + [key], to: .null)
        }
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encodeIfPresent(_ value: Int?, forKey key: Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            context.set(codingPath + [key], to: .null)
        }
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encodeIfPresent(_ value: Int8?, forKey key: Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            context.set(codingPath + [key], to: .null)
        }
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encodeIfPresent(_ value: Int16?, forKey key: Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            context.set(codingPath + [key], to: .null)
        }
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encodeIfPresent(_ value: Int32?, forKey key: Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            context.set(codingPath + [key], to: .null)
        }
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encodeIfPresent(_ value: Int64?, forKey key: Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            context.set(codingPath + [key], to: .null)
        }
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encodeIfPresent(_ value: UInt?, forKey key: Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            context.set(codingPath + [key], to: .null)
        }
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encodeIfPresent(_ value: UInt8?, forKey key: Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            context.set(codingPath + [key], to: .null)
        }
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encodeIfPresent(_ value: UInt16?, forKey key: Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            context.set(codingPath + [key], to: .null)
        }
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encodeIfPresent(_ value: UInt32?, forKey key: Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            context.set(codingPath + [key], to: .null)
        }
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encodeIfPresent(_ value: UInt64?, forKey key: Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            context.set(codingPath + [key], to: .null)
        }
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func encodeIfPresent<T>(_ value: T?, forKey key: Key) throws where T : Encodable {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            context.set(codingPath + [key], to: .null)
        }
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        return .init(_CodableDataKeyedEncoder<NestedKey>(context: context, codingPath: codingPath + [key]))
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func superEncoder() -> Encoder {
        fatalError()
    }
    
    /// See `KeyedEncodingContainerProtocol`.
    mutating func superEncoder(forKey key: Key) -> Encoder {
        fatalError()
    }
}

/// Private `SingleValueEncodingContainer` powering `CodableDataEncoder`.
private struct _CodableDataSingleValueEncoder: SingleValueEncodingContainer {
    /// Reference-based encoder context.
    let context: _CodableDataContext
    
    /// See `SingleValueEncodingContainer`.
    let codingPath: [CodingKey]
    
    /// Creates a new `_CodableDataSingleValueEncoder`.
    init(context: _CodableDataContext, codingPath: [CodingKey]) {
        self.context = context
        self.codingPath = codingPath
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encodeNil() throws {
        context.set(codingPath, to: .null)
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: Bool) throws {
        context.set(codingPath, to: .bool(value))
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: String) throws {
        context.set(codingPath, to: .string(value))
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: Double) throws {
        context.set(codingPath, to: .double(value))
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: Float) throws {
        context.set(codingPath, to: .float(value))
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: Int) throws {
        context.set(codingPath, to: .int(value))
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: Int8) throws {
        context.set(codingPath, to: .int8(value))
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: Int16) throws {
        context.set(codingPath, to: .int16(value))
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: Int32) throws {
        context.set(codingPath, to: .int32(value))
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: Int64) throws {
        context.set(codingPath, to: .int64(value))
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: UInt) throws {
        context.set(codingPath, to: .uint(value))
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: UInt8) throws {
        context.set(codingPath, to: .uint8(value))
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: UInt16) throws {
        context.set(codingPath, to: .uint16(value))
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: UInt32) throws {
        context.set(codingPath, to: .uint32(value))
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: UInt64) throws {
        context.set(codingPath, to: .uint64(value))
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        context.set(codingPath, to: .encodable(value))
    }
}
