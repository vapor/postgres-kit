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
            let context = _PostgreSQLDataEncoderContext()
            try encodable.encode(to: _PostgreSQLDataEncoder(context))
            guard let data = context.data else {
                throw PostgreSQLError(identifier: "dataEncode", reason: "Could not convert to `PostgreSQLData`: \(encodable)")
            }
            return data
        }
    }
}

// MARK: Private

/// Reference-based encoder context.
private final class _PostgreSQLDataEncoderContext {
    /// Encoded data.
    var data: PostgreSQLData?
    
    /// Creates a new `_PostgreSQLDataEncoderContext`.
    init() { }
}

/// Private `Encoder` powering `PostgreSQLDataEncoder`.
private struct _PostgreSQLDataEncoder: Encoder {
    /// See `Encoder`.
    let codingPath: [CodingKey] = []
    
    /// See `Encoder`.
    let userInfo: [CodingUserInfoKey: Any] = [:]
    
    /// Reference-based encoder context.
    let context: _PostgreSQLDataEncoderContext
    
    /// Creates a new `_PostgreSQLDataEncoder`.
    init(_ context: _PostgreSQLDataEncoderContext) {
        self.context = context
    }
    
    /// See `Encoder`.
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        fatalError()
    }
    
    /// See `Encoder`.
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    /// See `Encoder`.
    func singleValueContainer() -> SingleValueEncodingContainer {
        return _PostgreSQLDataSingleValueEncoder(context)
    }
}

/// Private `SingleValueEncodingContainer` powering `PostgreSQLDataEncoder`.
private struct _PostgreSQLDataSingleValueEncoder: SingleValueEncodingContainer {
    /// Reference-based encoder context.
    let context: _PostgreSQLDataEncoderContext
    
    /// See `SingleValueEncodingContainer`.
    let codingPath: [CodingKey] = []
    
    /// Creates a new `_PostgreSQLDataSingleValueEncoder`.
    init(_ context: _PostgreSQLDataEncoderContext) {
        self.context = context
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encodeNil() throws {
        context.data = PostgreSQLData(null: .void)
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: Bool) throws {
        context.data = try value.convertToPostgreSQLData()
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: String) throws {
        context.data = try value.convertToPostgreSQLData()
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: Double) throws {
        context.data = try value.convertToPostgreSQLData()
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: Float) throws {
        context.data = try value.convertToPostgreSQLData()
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: Int) throws {
        context.data = try value.convertToPostgreSQLData()
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: Int8) throws {
        context.data = try value.convertToPostgreSQLData()
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: Int16) throws {
        context.data = try value.convertToPostgreSQLData()
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: Int32) throws {
        context.data = try value.convertToPostgreSQLData()
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: Int64) throws {
        context.data = try value.convertToPostgreSQLData()
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: UInt) throws {
        context.data = try value.convertToPostgreSQLData()
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: UInt8) throws {
        context.data = try value.convertToPostgreSQLData()
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: UInt16) throws {
        context.data = try value.convertToPostgreSQLData()
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: UInt32) throws {
        context.data = try value.convertToPostgreSQLData()
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode(_ value: UInt64) throws {
        context.data = try value.convertToPostgreSQLData()
    }
    
    /// See `SingleValueEncodingContainer`.
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        if let convertible = value as? PostgreSQLDataConvertible {
            // this type has custom data conversion logic
            context.data = try convertible.convertToPostgreSQLData()
        } else {
            // nest one layer deeper
            return try value.encode(to: _PostgreSQLDataEncoder(context))
        }
    }
}
