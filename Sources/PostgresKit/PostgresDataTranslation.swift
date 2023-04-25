import PostgresNIO
import Foundation

/// Quick and dirty ``CodingKey``, borrowed from FluentKit. If ``CodingKeyRepresentable`` wasn't broken by design
/// (specifically, it can't be back-deployed before macOS 12.3 etc., even though it was introduced in Swift 5.6),
/// we'd use that instead.
fileprivate struct SomeCodingKey: CodingKey, Hashable {
    let stringValue: String, intValue: Int?
    init(stringValue: String) { (self.stringValue, self.intValue) = (stringValue, Int(stringValue)) }
    init(intValue: Int) { (self.stringValue, self.intValue) = ("\(intValue)", intValue) }
}

private extension PostgresCell {
    var codingKey: any CodingKey { SomeCodingKey(stringValue: !self.columnName.isEmpty ? "\(self.columnName) (\(self.columnIndex))" : "\(self.columnIndex)") }
}

internal struct PostgresDataTranslation {
    /// This typealias serves to limit the deprecation noise caused by ``PostgresDatConvertible`` to a single
    /// warning, down from what would otherwise be a minimum of two. It has no other purpose.
    fileprivate typealias PostgresLegacyDataConvertible = PostgresDataConvertible
    
    static func decode<T: Decodable, D: PostgresJSONDecoder>(
        _: T.Type = T.self,
        from cell: PostgresCell,
        in context: PostgresDecodingContext<D>,
        file: String = #fileID, line: Int = #line
    ) throws -> T {
        try self.decode(codingPath: [cell.codingKey], userInfo: [:], T.self, from: cell, in: context, file: file, line: line)
    }
    
    fileprivate static func decode<T: Decodable, D: PostgresJSONDecoder>(
        codingPath: [any CodingKey], userInfo: [CodingUserInfoKey: Any],
        _: T.Type = T.self,
        from cell: PostgresCell,
        in context: PostgresDecodingContext<D>,
        file: String, line: Int
    ) throws -> T {
        /// Preferred modern fast-path: Direct conformance to ``PostgresDecodable``, let the cell decode.
        if let fastPathType = T.self as? any PostgresDecodable.Type {
            return try cell.decode(fastPathType, context: context) as! T
        /// Legacy "fast"-path: Direct conformance to ``PostgresDataConvertible``; use is deprecated.
        } else if let legacyPathType = T.self as? any PostgresLegacyDataConvertible.Type {
            let legacyData = PostgresData(type: cell.dataType, typeModifier: nil, formatCode: cell.format, value: cell.bytes)

            guard let result = legacyPathType.init(postgresData: legacyData) else {
                throw DecodingError.typeMismatch(T.self, .init(codingPath: codingPath,
                    debugDescription: "Couldn't get '\(T.self)' from PSQL type \(cell.dataType): \(legacyData as Any)"
                ))
            }
            return result as! T
        }
        /// Slow path: Descend through the ``Decodable`` machinery until we fail or find something we can convert.
        else {
            do {
                return try T.init(from: ArrayAwareBoxUwrappingDecoder<T, D>(codingPath: codingPath, userInfo: userInfo, cell: cell, context: context, file: file, line: line))
            } catch DecodingError.dataCorrupted {
                /// Glacial path: Attempt to decode as plain JSON.
                guard cell.dataType == .json || cell.dataType == .jsonb else {
                    throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Unable to interpret value of PSQL type \(cell.dataType): \(cell.bytes.map { "\($0)" } ?? "null")"))
                }
                if cell.dataType == .jsonb, cell.format == .binary, let buffer = cell.bytes {
                    // TODO: Un-hardcode this magic knowledge of the JSONB encoding
                    return try context.jsonDecoder.decode(T.self, from: buffer.getSlice(at: buffer.readerIndex + 1, length: buffer.readableBytes - 1) ?? .init())
                } else {
                    return try context.jsonDecoder.decode(T.self, from: cell.bytes ?? .init())
                }
            }
        }
    }
    
    static func encode<T: Encodable, E: PostgresJSONEncoder>(
        value: T,
        in context: PostgresEncodingContext<E>,
        to bindings: inout PostgresBindings,
        file: String = #fileID, line: Int = #line
    ) throws {
        /// Preferred modern fast-path: Direct conformance to ``PostgresEncodable``
        if let fastPathValue = value as? any PostgresEncodable {
            try bindings.append(fastPathValue, context: context)
        }
        /// Legacy "fast"-path: Direct conformance to ``PostgresDataConvertible``; use is deprecated.
        else if let legacyPathValue = value as? any PostgresDataTranslation.PostgresLegacyDataConvertible {
            guard let legacyData = legacyPathValue.postgresData else {
                throw EncodingError.invalidValue(value, .init(codingPath: [], debugDescription: "Couldn't get PSQL encoding from value '\(value)'"))
            }
            bindings.append(legacyData)
        }
        /// Slow path: Descend through the ``Encodable`` machinery until we fail or find something we can convert.
        else {
            try bindings.append(self.encode(codingPath: [], userInfo: [:], value: value, in: context, file: file, line: line))
        }
    }
    
    internal/*fileprivate*/ static func encode<T: Encodable, E: PostgresJSONEncoder>(
        codingPath: [any CodingKey], userInfo: [CodingUserInfoKey: Any],
        value: T,
        in context: PostgresEncodingContext<E>,
        file: String, line: Int
    ) throws -> PostgresData {
        // TODO: Make all of this work without relying on the legacy PostgresData array machinery
        do {
            let encoder = ArrayAwareBoxWrappingPostgresEncoder(codingPath: codingPath, userInfo: userInfo, context: context, file: file, line: line)
            try value.encode(to: encoder)
            switch encoder.value {
            case .invalid: throw ArrayAwareBoxWrappingPostgresEncoder<E>.FallbackSentinel()
            case .scalar(let scalar): return scalar
            case .indexed(let ref):
                let elementType = ref.contents.first?.type ?? .jsonb
                assert(ref.contents.allSatisfy { $0.type == elementType }, "Type \(type(of: value)) was encoded as a heterogenous array; this is unsupported.")
                return PostgresData(array: ref.contents, elementType: elementType)
            }
        } catch is ArrayAwareBoxWrappingPostgresEncoder<E>.FallbackSentinel {
            /// Glacial path: Fall back to encoding directly to JSON.
            return try PostgresData(jsonb: context.jsonEncoder.encode(value))
        }
    }
}

private final class ArrayAwareBoxUwrappingDecoder<T0: Decodable, D: PostgresJSONDecoder>: Decoder, SingleValueDecodingContainer {
    let codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]
    let cell: PostgresCell, context: PostgresDecodingContext<D>
    let file: String, line: Int
 
    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any], cell: PostgresCell, context: PostgresDecodingContext<D>, file: String, line: Int) {
        self.codingPath = codingPath
        self.cell = cell
        self.context = context
        self.file = file
        self.line = line
        self.userInfo = userInfo
    }
    
    struct ArrayContainer: UnkeyedDecodingContainer {
        let data: [PostgresData], decoder: ArrayAwareBoxUwrappingDecoder
        var codingPath: [CodingKey] { self.decoder.codingPath }
        var count: Int? { self.data.count }
        var isAtEnd: Bool { self.currentIndex >= self.data.count }
        var currentIndex = 0
        
        mutating func decodeNil() throws -> Bool {
            guard self.data[self.currentIndex].value == nil else { return false }
            self.currentIndex += 1
            return true
        }
        
        mutating func decode<T: Decodable>(_: T.Type) throws -> T {
            // TODO: Don't fake a cell.
            let data = self.data[self.currentIndex], cell = PostgresCell(
                bytes: data.value, dataType: data.type, format: data.formatCode,
                columnName: self.decoder.cell.columnName, columnIndex: self.decoder.cell.columnIndex
            )
            let result = try PostgresDataTranslation.decode(
                codingPath: self.codingPath + [SomeCodingKey(intValue: self.currentIndex)],
                userInfo: self.decoder.userInfo,
                T.self, from: cell, in: self.decoder.context, file: self.decoder.file, line: self.decoder.line
            )
            self.currentIndex += 1
            return result
        }
        
        private var rejectNestingError: DecodingError { .dataCorruptedError(in: self, debugDescription: "Data nesting is not supported") }
        mutating func nestedContainer<K: CodingKey>(keyedBy: K.Type) throws -> KeyedDecodingContainer<K> { throw self.rejectNestingError }
        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer { throw self.rejectNestingError }
        mutating func superDecoder() throws -> Decoder { throw self.rejectNestingError }
    }
    
    func container<Key: CodingKey>(keyedBy: Key.Type) throws -> KeyedDecodingContainer<Key> {
        throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Dictionary containers must be JSON-encoded"))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        // TODO: Find a better way to figure out arrays
        guard let array = PostgresData(type: self.cell.dataType, typeModifier: nil, formatCode: self.cell.format, value: self.cell.bytes).array else {
            throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Non-natively typed arrays must be JSON-encoded"))
        }
        return ArrayContainer(data: array, decoder: self)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer { self }
    
    func decodeNil() -> Bool { self.cell.bytes == nil }
    
    func decode<T: Decodable>(_: T.Type) throws -> T {
        try PostgresDataTranslation.decode(
            codingPath: self.codingPath + [SomeCodingKey(stringValue: "(Unwrapping(\(T0.self)))")], userInfo: self.userInfo,
            T.self, from: self.cell, in: self.context, file: self.file, line: self.line
        )
    }
}

private final class ArrayAwareBoxWrappingPostgresEncoder<E: PostgresJSONEncoder>: Encoder, SingleValueEncodingContainer {
    enum Value {
        final class ArrayRef<T> { var contents: [T] = [] }
        
        case invalid
        case indexed(ArrayRef<PostgresData>)
        case scalar(PostgresData)
        
        var isValid: Bool { if case .invalid = self { return false }; return true }

        mutating func store(scalar: PostgresData) {
            if case .invalid = self { self = .scalar(scalar) } // no existing value, store the incoming
            else { preconditionFailure("Invalid request for multiple containers from the same encoder.") }
        }

        mutating func requestIndexed() {
            switch self {
            case .scalar(_): preconditionFailure("Invalid request for both single-value and unkeyed containers from the same encoder.")
            case .invalid: self = .indexed(.init()) // no existing value, make new array
            case .indexed(_): break // existing array, adopt it for appending (support for superEncoder())
            }
        }
        
        var indexedCount: Int {
            if case .indexed(let ref) = self { return ref.contents.count }
            else { preconditionFailure("Internal error in encoder (requested indexed count from non-indexed state)") }
        }

        mutating func store(indexedScalar: PostgresData) {
            if case .indexed(let ref) = self { ref.contents.append(indexedScalar) }
            else { preconditionFailure("Internal error in encoder (attempted store to indexed in non-indexed state)") }
        }
    }
    
    var codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any]
    let context: PostgresEncodingContext<E>
    let file: String, line: Int
    var value: Value

    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any], context: PostgresEncodingContext<E>, file: String, line: Int, value: Value = .invalid) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.context = context
        self.file = file
        self.line = line
        self.value = value
    }
    
    func container<K: CodingKey>(keyedBy: K.Type) -> KeyedEncodingContainer<K> {
        precondition(!self.value.isValid, "Requested multiple containers from the same encoder.")
        return .init(FailureEncoder())
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        self.value.requestIndexed()
        return ArrayContainer(encoder: self)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        precondition(!self.value.isValid, "Requested multiple containers from the same encoder.")
        return self
    }
    
    struct ArrayContainer: UnkeyedEncodingContainer {
        let encoder: ArrayAwareBoxWrappingPostgresEncoder
        var codingPath: [CodingKey] { self.encoder.codingPath }
        var count: Int { self.encoder.value.indexedCount }
        mutating func encodeNil() throws { self.encoder.value.store(indexedScalar: .null) }
        mutating func encode<T: Encodable>(_ value: T) throws {
            self.encoder.value.store(indexedScalar: try PostgresDataTranslation.encode(
                codingPath: self.codingPath + [SomeCodingKey(intValue: self.count)], userInfo: self.encoder.userInfo,
                value: value, in: self.encoder.context,
                file: self.encoder.file, line: self.encoder.line
            ))
        }
        mutating func nestedContainer<K: CodingKey>(keyedBy: K.Type) -> KeyedEncodingContainer<K> { self.superEncoder().container(keyedBy: K.self) }
        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer { self.superEncoder().unkeyedContainer() }
        mutating func superEncoder() -> Encoder { ArrayAwareBoxWrappingPostgresEncoder(
            codingPath: self.codingPath + [SomeCodingKey(intValue: self.count)], userInfo: self.encoder.userInfo,
            context: self.encoder.context,
            file: self.encoder.file, line: self.encoder.line,
            value: self.encoder.value
        ) } // NOT the same as self.encoder
    }

    func encodeNil() throws { self.value.store(scalar: .null) }
    func encode<T: Encodable>(_ value: T) throws {
        self.value.store(scalar: try PostgresDataTranslation.encode(
            codingPath: self.codingPath, userInfo: self.userInfo, value: value, in: self.context, file: self.file, line: self.line
        ))
    }
    
    struct FallbackSentinel: Error {}

    /// This is a workaround for the inability of encoders to throw errors in various places. It's still better than fatalError()ing.
    struct FailureEncoder<K: CodingKey>: Encoder, KeyedEncodingContainerProtocol, UnkeyedEncodingContainer, SingleValueEncodingContainer {
        let codingPath = [CodingKey](), userInfo = [CodingUserInfoKey: Any](), count = 0
        init() {}; init() where K == SomeCodingKey {}
        func encodeNil() throws { throw FallbackSentinel() }
        func encodeNil(forKey: K) throws { throw FallbackSentinel() }
        func encode<T: Encodable>(_: T) throws { throw FallbackSentinel() }
        func encode<T: Encodable>(_: T, forKey: K) throws { throw FallbackSentinel() }
        func nestedContainer<N: CodingKey>(keyedBy: N.Type) -> KeyedEncodingContainer<N> { .init(FailureEncoder<N>()) }
        func nestedContainer<N: CodingKey>(keyedBy: N.Type, forKey: K) -> KeyedEncodingContainer<N> { .init(FailureEncoder<N>()) }
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer { self }
        func nestedUnkeyedContainer(forKey: K) -> UnkeyedEncodingContainer { self }
        func superEncoder() -> Encoder { self }
        func superEncoder(forKey: K) -> Encoder { self }
        func container<K: CodingKey>(keyedBy: K.Type) -> KeyedEncodingContainer<K> { .init(FailureEncoder<K>()) }
        func unkeyedContainer() -> UnkeyedEncodingContainer { self }
        func singleValueContainer() -> SingleValueEncodingContainer { self }
    }

    // TODO: Finish all this and make it work
    /*
    enum State {
        typealias ValueBinder = (inout PostgresBindings) throws -> Void
        final class ArrayRef<T> { var contents: [T] = []; func append(_ value: T) { self.contents.append(value) } }

        case start
        case invalidOperation(Error)
        case haveScalarValue(ValueBinder)
        case haveHomogenousArray(ArrayRef<PostgresData>)
        
        mutating func handleInvalidOperation<T>(value: T, at codingPath: [CodingKey], description: String) {
            if case .invalidOperation(_) = self { return }
            self = .invalidOperation(EncodingError.invalidValue(value, .init(codingPath: codingPath, debugDescription: description)))
        }
        
        mutating func handleProvideScalarValue<T: Encodable>(_ value: T, at codingPath: [CodingKey], withBinder binder: @escaping ValueBinder) {
            switch self {
            case .start: self = .haveScalarValue(binder)
            default:     self.handleInvalidOperation(value: value, at: codingPath, description: "Can't encode scalar value in current state.")
            }
        }
        
        mutating func handleStartArray(at codingPath: [CodingKey]) {
            switch self {
            case .start: self = .haveHomogenousArray(.init())
            default:     self.handleInvalidOperation(value: [PostgresData](), at: codingPath, description: "Can't encode array in current state.")
        }
    }
    var state: State
    */
}
