import Foundation
import protocol PostgresNIO.PostgresJSONEncoder
import var PostgresNIO._defaultJSONEncoder

public final class PostgresDataEncoder {
    public let json: PostgresJSONEncoder

    public init(json: PostgresJSONEncoder = PostgresNIO._defaultJSONEncoder) {
        self.json = json
    }

    public func encode(_ value: Encodable) throws -> PostgresData {
        if let custom = value as? PostgresDataConvertible, let data = custom.postgresData {
            return data
        } else {
            let encoder = _Encoder(parent: self)
            do {
                try value.encode(to: encoder)
                switch encoder.value {
                case .invalid: throw _Encoder.AssociativeValueSentinel() // this is usually "nothing was encoded at all", not an associative value, but the desired action is the same
                case .scalar(let scalar): return scalar
                case .indexed(let indexed):
                    let elementType = indexed.contents.first?.type ?? .jsonb
                    assert(indexed.contents.allSatisfy { $0.type == elementType }, "Type \(type(of: value)) was encoded as a heterogenous array; this is unsupported.")
                    return PostgresData(array: indexed.contents, elementType: elementType)
                }
            } catch is _Encoder.AssociativeValueSentinel {
#if swift(<5.7)
                struct _Wrapper: Encodable {
                    let encodable: Encodable
                    init(_ encodable: Encodable) { self.encodable = encodable }
                    func encode(to encoder: Encoder) throws { try self.encodable.encode(to: encoder) }
                }
                return try PostgresData(jsonb: self.json.encode(_Wrapper(value))) // Swift <5.7 will complain that "Encodable does not conform to Encodable" without the wrapper
#else
                return try PostgresData(jsonb: self.json.encode(value))
#endif
            }
        }
    }

    private final class _Encoder: Encoder {
        struct AssociativeValueSentinel: Error {}
        enum Value {
            final class RefArray<T> { var contents: [T] = [] }
            case invalid, indexed(RefArray<PostgresData>), scalar(PostgresData)
            
            var isValid: Bool { if case .invalid = self { return false }; return true }
            mutating func requestIndexed(for encoder: _Encoder) {
                switch self {
                case .scalar(_): preconditionFailure("Invalid request for both single-value and unkeyed containers from the same encoder.")
                case .invalid: self = .indexed(.init()) // no existing value, make new array
                case .indexed(_): break // existing array, adopt it for appending (support for superEncoder())
                }
            }
            mutating func storeScalar(_ scalar: PostgresData) {
                switch self {
                case .indexed(_), .scalar(_): preconditionFailure("Invalid request for multiple containers from the same encoder.")
                case .invalid: self = .scalar(scalar) // no existing value, store the incoming
                }
            }
            var indexedCount: Int {
                switch self {
                case .invalid, .scalar(_): preconditionFailure("Internal error in encoder (requested indexed count from non-indexed state)")
                case .indexed(let ref): return ref.contents.count
                }
            }
            mutating func addToIndexed(_ scalar: PostgresData) {
                switch self {
                case .invalid, .scalar(_): preconditionFailure("Internal error in encoder (attempted store to indexed in non-indexed state)")
                case .indexed(let ref): ref.contents.append(scalar)
                }
            }
        }
        
        var userInfo: [CodingUserInfoKey : Any] { [:] }; var codingPath: [CodingKey] { [] }
        var parent: PostgresDataEncoder, value: Value
        
        init(parent: PostgresDataEncoder, value: Value = .invalid) { (self.parent, self.value) = (parent, value) }
        func container<K: CodingKey>(keyedBy: K.Type) -> KeyedEncodingContainer<K> {
            precondition(!self.value.isValid, "Requested multiple containers from the same encoder.")
            return .init(_FailingKeyedContainer())
        }
        func unkeyedContainer() -> UnkeyedEncodingContainer {
            self.value.requestIndexed(for: self)
            return _UnkeyedValueContainer(encoder: self)
        }
        func singleValueContainer() -> SingleValueEncodingContainer {
            precondition(!self.value.isValid, "Requested multiple containers from the same encoder.")
            return _SingleValueContainer(encoder: self)
        }
        
        struct _UnkeyedValueContainer: UnkeyedEncodingContainer {
            let encoder: _Encoder; var codingPath: [CodingKey] { self.encoder.codingPath }
            var count: Int { self.encoder.value.indexedCount }
            mutating func encodeNil() throws { self.encoder.value.addToIndexed(.null) }
            mutating func encode<T: Encodable>(_ value: T) throws { self.encoder.value.addToIndexed(try self.encoder.parent.encode(value)) }
            mutating func nestedContainer<K: CodingKey>(keyedBy: K.Type) -> KeyedEncodingContainer<K> { self.superEncoder().container(keyedBy: K.self) }
            mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer { self.superEncoder().unkeyedContainer() }
            mutating func superEncoder() -> Encoder { _Encoder(parent: self.encoder.parent, value: self.encoder.value) } // NOT the same as self.encoder
        }

        struct _SingleValueContainer: SingleValueEncodingContainer {
            let encoder: _Encoder; var codingPath: [CodingKey] { self.encoder.codingPath }
            func encodeNil() throws { self.encoder.value.storeScalar(.null) }
            func encode<T: Encodable>(_ value: T) throws { self.encoder.value.storeScalar(try self.encoder.parent.encode(value)) }
        }
        
        /// This pair of types is only necessary because we can't directly throw an error from various Encoder and
        /// encoding container methods. We define duplicate types rather than the old implementation's use of a
        /// no-action keyed container because it can save a significant amount of time otherwise spent uselessly calling
        /// nested methods in some cases.
        struct _TaintedEncoder: Encoder, UnkeyedEncodingContainer, SingleValueEncodingContainer {
            var userInfo: [CodingUserInfoKey : Any] { [:] }; var codingPath: [CodingKey] { [] }; var count: Int { 0 }
            func container<K: CodingKey>(keyedBy: K.Type) -> KeyedEncodingContainer<K> { .init(_FailingKeyedContainer()) }
            func nestedContainer<K: CodingKey>(keyedBy: K.Type) -> KeyedEncodingContainer<K> { .init(_FailingKeyedContainer()) }
            func unkeyedContainer() -> UnkeyedEncodingContainer { self }
            func nestedUnkeyedContainer() -> UnkeyedEncodingContainer { self }
            func singleValueContainer() -> SingleValueEncodingContainer { self }
            func superEncoder() -> Encoder { self }
            func encodeNil() throws { throw AssociativeValueSentinel() }
            func encode<T: Encodable>(_: T) throws { throw AssociativeValueSentinel() }
        }
        struct _FailingKeyedContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
            var codingPath: [CodingKey] { [] }
            func encodeNil(forKey: K) throws { throw AssociativeValueSentinel() }
            func encode<T: Encodable>(_: T, forKey: K) throws { throw AssociativeValueSentinel() }
            func nestedContainer<NK: CodingKey>(keyedBy: NK.Type, forKey: K) -> KeyedEncodingContainer<NK> { .init(_FailingKeyedContainer<NK>()) }
            func nestedUnkeyedContainer(forKey: K) -> UnkeyedEncodingContainer { _TaintedEncoder() }
            func superEncoder() -> Encoder { _TaintedEncoder() }
            func superEncoder(forKey: K) -> Encoder { _TaintedEncoder() }
        }
    }
}
