import Foundation
import PostgresNIO
import SQLKit

extension PostgresCell {
    fileprivate var codingKey: any CodingKey {
        SomeCodingKey(stringValue: !self.columnName.isEmpty ? "\(self.columnName) (\(self.columnIndex))" : "\(self.columnIndex)")
    }
}

fileprivate protocol OptionalType { associatedtype Wrapped }
extension Optional: OptionalType {}

fileprivate protocol OptionalPostgresArrayEncodableCollection {
    static var psqlArrayType: PostgresDataType { get }
}
extension Array: OptionalPostgresArrayEncodableCollection where Self.Element: OptionalType, Self.Element.Wrapped: PostgresArrayEncodable {
    static var psqlArrayType: PostgresDataType { Self.Element.Wrapped.psqlArrayType }
}

/// Sidestep problems with URL coding behavior by making it conform directly to Postgres coding.
extension URL {
    public static var psqlType: PostgresDataType {
        String.psqlType
    }

    public static var psqlFormat: PostgresFormat {
        String.psqlFormat
    }

    @inlinable
    public func encode(
        into byteBuffer: inout ByteBuffer,
        context: PostgresEncodingContext<some PostgresJSONEncoder>
    ) {
        self.absoluteString.encode(into: &byteBuffer, context: context)
    }

    @inlinable
    public init(
        from buffer: inout ByteBuffer,
        type: PostgresDataType,
        format: PostgresFormat,
        context: PostgresDecodingContext<some PostgresJSONDecoder>
    ) throws {
        let string = try String(from: &buffer, type: type, format: format, context: context)

        if let url = URL(string: string) {
            self = url
        }
        // Also support the broken encoding we were emitting for awhile there.
        else if string.hasPrefix("\""), string.hasSuffix("\""), let url = URL(string: String(string.dropFirst().dropLast())) {
            self = url
        } else {
            throw PostgresDecodingError.Code.failure
        }
    }
}

extension URL: @retroactive PostgresNonThrowingEncodable, @retroactive PostgresDecodable {}

struct PostgresDataTranslation {
    /// This typealias serves to limit the deprecation noise caused by `PostgresDataConvertible` to a single
    /// warning, down from what would otherwise be a minimum of two. It has no other purpose.
    fileprivate typealias PostgresLegacyDataConvertible = PostgresDataConvertible

    static func decode<T: Decodable, D: PostgresJSONDecoder>(
        _: T.Type = T.self,
        from cell: PostgresCell,
        in context: PostgresDecodingContext<D>,
        file: String = #fileID,
        line: Int = #line
    ) throws -> T {
        try self.decode(
            codingPath: [cell.codingKey],
            userInfo: [:],
            T.self,
            from: cell,
            in: context,
            file: file,
            line: line
        )
    }

    fileprivate static func decode<T: Decodable, D: PostgresJSONDecoder>(
        codingPath: [any CodingKey],
        userInfo: [CodingUserInfoKey: Any],
        _: T.Type = T.self,
        from cell: PostgresCell,
        in context: PostgresDecodingContext<D>,
        file: String,
        line: Int
    ) throws -> T {
        /// Preferred modern fast-path: Direct conformance to `PostgresDecodable`, let the cell decode.
        if let fastPathType = T.self as? any PostgresDecodable.Type {
            let cellToDecode: PostgresCell

            if cell.dataType.isUserDefined && (T.self is String.Type || T.self is String?.Type) {
                /// Workaround for Fluent's enum "support":
                ///
                /// If we're trying to decode a string and the real cell's data type is in the user-defined range,
                /// assume we're dealing with a Fluent enum and pretend that the cell has a string data type instead.
                cellToDecode = .init(
                    bytes: cell.bytes,
                    dataType: .name,
                    format: cell.format,
                    columnName: cell.columnName,
                    columnIndex: cell.columnIndex
                )
            } else if cell.format == .binary && [.char, .varchar, .text].contains(cell.dataType) && T.self is Decimal.Type {
                /// Workaround for Fluent's assumption that Decimal strings work:
                ///
                /// If the cell's data type is a binary-format string-like, and we're trying to decode a `Decimal`,
                /// reinterpret the cell as a text-format numeric value so that the `PostgresCodable` conformance of
                /// `Decimal` will work as written.
                cellToDecode = .init(
                    bytes: cell.bytes,
                    dataType: .numeric,
                    format: .text,
                    columnName: cell.columnName,
                    columnIndex: cell.columnIndex
                )
            } else if cell.format == .binary && cell.dataType == .numeric && T.self is Double.Type {
                /// Workaround for Fluent's expectation that Postgres's `numeric/decimal` can be decoded as `Double`:
                /// decode the cell as `Decimal` (which understands binary numeric) and convert.
                guard var bytes = cell.bytes else {
                    throw DecodingError.valueNotFound(T.self, .init(codingPath: codingPath, debugDescription: "Binary numeric cell has no bytes"))
                }
                let decimal: Decimal
                do {
                    decimal = try Decimal(from: &bytes, type: cell.dataType, format: cell.format, context: context)
                } catch {
                    throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Invalid numeric value encoding", underlyingError: error))
                }
                guard let value = Double(decimal.description) else {
                    throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Numeric value \(decimal) is not representable as Double"))
                }
                return value as! T
            } else {
                /// No workarounds needed, use the cell as-is.
                cellToDecode = cell
            }
            return try cellToDecode.decode(fastPathType, context: context, file: file, line: line) as! T

        /// Legacy "fast"-path: Direct conformance to `PostgresDataConvertible`; use is deprecated.
        } else if let legacyPathType = T.self as? any PostgresLegacyDataConvertible.Type {
            let legacyData = PostgresData(type: cell.dataType, typeModifier: nil, formatCode: cell.format, value: cell.bytes)

            guard let result = legacyPathType.init(postgresData: legacyData) else {
                throw DecodingError.typeMismatch(T.self, .init(codingPath: codingPath,
                    debugDescription: "Couldn't get '\(T.self)' from PSQL type \(cell.dataType): \(legacyData as Any)"
                ))
            }
            return result as! T
        }

        /// Slow path: Descend through the `Decodable` machinery until we fail or find something we can convert.
        else {
            do {
                return try T.init(from: ArrayAwareBoxUwrappingDecoder<T, D>(
                    codingPath: codingPath,
                    userInfo: userInfo,
                    cell: cell,
                    context: context,
                    file: file, line: line
                ))
            } catch DecodingError.dataCorrupted(let errContext) {
                /// Glacial path: Attempt to decode as plain JSON.
                guard cell.dataType == .json || cell.dataType == .jsonb else {
                    throw DecodingError.dataCorrupted(.init(
                        codingPath: codingPath,
                        debugDescription: "Unable to interpret value of PSQL type \(cell.dataType) as Swift type \(T.self): \(cell.bytes.map { "\($0)" } ?? "null")",
                        underlyingError: DecodingError.dataCorrupted(errContext)
                    ))
                }
                if cell.dataType == .jsonb, cell.format == .binary, let buffer = cell.bytes {
                    // Account for the leading JSONB version byte
                    return try context.jsonDecoder.decode(T.self, from: buffer.getSlice(at: buffer.readerIndex + 1, length: buffer.readableBytes - 1) ?? .init())
                } else {
                    return try context.jsonDecoder.decode(T.self, from: cell.bytes ?? .init())
                }
            } catch let error as PostgresDecodingError {
                /// We effectively transform PostgresDecodingErrors into plain DecodingErrors here, mostly so the full
                /// coding path, which gives us the original type(s) involved, is preserved.
                let context = DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "\(String(reflecting: error))",
                    underlyingError: error
                )

                switch error.code {
                case .typeMismatch: throw DecodingError.typeMismatch(T.self, context)
                case .missingData: throw DecodingError.valueNotFound(T.self, context)
                default: throw DecodingError.dataCorrupted(context)
                }
            }
        }
    }

    static func encode<T: Encodable, E: PostgresJSONEncoder>(
        value: T,
        in context: PostgresEncodingContext<E>,
        to bindings: inout PostgresBindings,
        file: String = #fileID,
        line: Int = #line
    ) throws {
        /// Nil bypass-path: Skip the entire machinery for nil optionals.
        if (value as Optional<Any>) == nil {
            bindings.appendNull()
        }
        /// Preferred fast-path: Direct conformance to the `PostgresEncodable` family.
        else if let fastPathValue = value as? any PostgresThrowingDynamicTypeEncodable {
            try bindings.append(fastPathValue, context: context)
        }
        /// Legacy "fast"-path: Direct conformance to `PostgresDataConvertible`; use is deprecated.
        else if let legacyPathValue = value as? any PostgresDataTranslation.PostgresLegacyDataConvertible {
            guard let legacyData = legacyPathValue.postgresData else {
                throw EncodingError.invalidValue(value, .init(codingPath: [], debugDescription: "Couldn't get PSQL encoding from value '\(value)' of Swift type \(type(of: value))"))
            }
            try bindings.append(legacyData.value == nil ? nil : LegacyDataBox(data: legacyData))
        }
        /// Slow path: Descend through the `Encodable` machinery.
        else {
            guard let encodable = try self.encode(codingPath: [], userInfo: [:], value: value, in: context, file: file, line: line) else {
                bindings.appendNull()
                return
            }
            try bindings.append(encodable, context: context)
        }
    }

    internal /*fileprivate*/ static func encode<T: Encodable, E: PostgresJSONEncoder>(
        codingPath: [any CodingKey],
        userInfo: [CodingUserInfoKey: Any],
        value: T,
        in context: PostgresEncodingContext<E>,
        file: String,
        line: Int
    ) throws -> (any PostgresThrowingDynamicTypeEncodable)? {
        /// Nil bypass-path: Skip the entire machinery for nil optionals.
        if (value as Optional<Any>) == nil { 
            return nil 
        }
        /// Preferred fast-path: Direct conformance to the `PostgresEncodable` family.
        else if let fastPathValue = value as? any PostgresThrowingDynamicTypeEncodable {
            return fastPathValue
        } else if let legacyPathValue = value as? any PostgresDataTranslation.PostgresLegacyDataConvertible {
            guard let legacyData = legacyPathValue.postgresData else {
                throw EncodingError.invalidValue(value, .init(codingPath: codingPath, debugDescription: "Couldn't get PSQL encoding from value '\(value)' of Swift type \(type(of: value))"))
            }
            return legacyData.value == nil ? nil : LegacyDataBox(data: legacyData)
        }
        do {
            let encoder = ArrayAwareBoxWrappingPostgresEncoder(codingPath: codingPath, userInfo: userInfo, context: context, file: file, line: line)
            try value.encode(to: encoder)
            switch encoder.value {
            case .invalid:
                throw ArrayAwareBoxWrappingPostgresEncoder<E>.FallbackSentinel()
            case .scalar(let scalar):
                return scalar
            case .indexed(let ref):
                let elementType = (T.self as? any OptionalPostgresArrayEncodableCollection.Type)?.psqlArrayType.psqlkit_elementType ?? (ref.contents.first)??.psqlType ?? .jsonb
                assert(
                    ref.contents.allSatisfy { $0.map { $0.psqlType == elementType } ?? true },
                    "Type \(Swift.type(of: value)) at \(codingPath.map(\.description).joined(separator: ".")) contains heterogenous elements; this is unsupported."
                )
                guard let array = PostgresDynamicArray(elementType: elementType, elements: ref.contents) else {
                    throw EncodingError.invalidValue(ref.contents, .init(codingPath: [], debugDescription: "Couldn't get OID type from value '\(value)' of Swift type \(type(of: value))"))
                }
                return array
            }
        } catch is ArrayAwareBoxWrappingPostgresEncoder<E>.FallbackSentinel {
            /// Glacial path: Fall back to encoding directly to JSON.
            return PostgresJSONBBox(value: value)
        }
    }
}

struct LegacyDataBox: PostgresThrowingDynamicTypeEncodable {
    let data: PostgresData  // non-null; nulls are handled before boxing

    var psqlType: PostgresDataType { self.data.type }
    var psqlFormat: PostgresFormat { self.data.formatCode }

    func encode<JSONEncoder: PostgresJSONEncoder>(
        into buffer: inout ByteBuffer,
        context: PostgresEncodingContext<JSONEncoder>
    ) throws {
        var value = self.data.value!  // guarded by the caller
        buffer.writeBuffer(&value)
    }
}

struct PostgresDynamicArray: PostgresThrowingDynamicTypeEncodable {
    var psqlFormat: PostgresFormat { .binary }
    var psqlType: PostgresDataType { self.arrayType }

    let arrayType: PostgresDataType

    init?(elementType: PostgresDataType, elements: [(any PostgresThrowingDynamicTypeEncodable)?]) {
        // If we don't know the OID upfront we cannot encode it and have to fall back
        guard let arrayType = elementType.psqlkit_arrayType else { return nil }
        self.arrayType = arrayType
        self.elementType = elementType
        self.elements = elements
    }

    let elementType: PostgresDataType
    let elements: [(any PostgresThrowingDynamicTypeEncodable)?]

    func encode<JSONEncoder>(
        into byteBuffer: inout ByteBuffer,
        context: PostgresEncodingContext<JSONEncoder>
    ) throws where JSONEncoder: PostgresJSONEncoder {
        byteBuffer.writeInteger(self.elements.isEmpty ? 0 : 1, as: UInt32.self)
        byteBuffer.writeInteger(0, as: Int32.self)
        byteBuffer.writeInteger(self.elementType.rawValue)
        
        guard !self.elements.isEmpty else { return }
        byteBuffer.writeInteger(Int32(elements.count))
        byteBuffer.writeInteger(1, as: Int32.self)

        for element in self.elements {
            if let element {
                let lengthIndex = byteBuffer.writerIndex
                byteBuffer.writeInteger(0, as: Int32.self)
                let start = byteBuffer.writerIndex
                try element.encode(into: &byteBuffer, context: context)
                byteBuffer.setInteger(Int32(byteBuffer.writerIndex - start), at: lengthIndex)
            } else {
                byteBuffer.writeInteger(-1, as: Int32.self)
            }
        }
    }
}

struct PostgresJSONBBox<T: Encodable>: PostgresEncodable {
    static var psqlType: PostgresDataType { .jsonb }
    static var psqlFormat: PostgresFormat { .binary }

    let value: T

    func encode<JSONEncoder>(
        into byteBuffer: inout ByteBuffer,
        context: PostgresEncodingContext<JSONEncoder>
    ) throws where JSONEncoder: PostgresJSONEncoder {
        byteBuffer.writeInteger(1, as: UInt8.self)
        try context.jsonEncoder.encode(value, into: &byteBuffer)
    }
}

private final class ArrayAwareBoxUwrappingDecoder<T0: Decodable, D: PostgresJSONDecoder>: Decoder, SingleValueDecodingContainer {
    let codingPath: [any CodingKey]
    let userInfo: [CodingUserInfoKey: Any]
    let cell: PostgresCell
    let context: PostgresDecodingContext<D>
    let file: String, line: Int
 
    init(codingPath: [any CodingKey], userInfo: [CodingUserInfoKey: Any], cell: PostgresCell, context: PostgresDecodingContext<D>, file: String, line: Int) {
        self.codingPath = codingPath
        self.cell = cell
        self.context = context
        self.file = file
        self.line = line
        self.userInfo = userInfo
    }

    struct ArrayContainer: UnkeyedDecodingContainer {
        let cells: [PostgresCell]
        let decoder: ArrayAwareBoxUwrappingDecoder

        var codingPath: [any CodingKey] {
            self.decoder.codingPath
        }

        var count: Int? {
            self.cells.count
        }

        var isAtEnd: Bool {
            self.currentIndex >= self.cells.count
        }

        var currentIndex = 0

        mutating func decodeNil() throws -> Bool {
            guard self.cells[self.currentIndex].bytes == nil else { return false }
            self.currentIndex += 1
            return true
        }

        mutating func decode<T: Decodable>(_: T.Type) throws -> T {
            let cell = self.cells[self.currentIndex]

            let result = try PostgresDataTranslation.decode(
                codingPath: self.codingPath + [SomeCodingKey(intValue: self.currentIndex)],
                userInfo: self.decoder.userInfo,
                T.self, from: cell, in: self.decoder.context,
                file: self.decoder.file, line: self.decoder.line
            )
            self.currentIndex += 1
            return result
        }

        private var rejectNestingError: DecodingError { .dataCorruptedError(in: self, debugDescription: "Data nesting is not supported") }
        mutating func nestedContainer<K: CodingKey>(keyedBy: K.Type) throws -> KeyedDecodingContainer<K> { throw self.rejectNestingError }
        mutating func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer { throw self.rejectNestingError }
        mutating func superDecoder() throws -> any Decoder { throw self.rejectNestingError }
    }

    func container<Key: CodingKey>(keyedBy: Key.Type) throws -> KeyedDecodingContainer<Key> {
        throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Dictionary containers must be JSON-encoded"))
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        // Read cells directly from the wire
        guard self.cell.format == .binary, var buffer = self.cell.bytes else {
            throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Non-natively typed arrays must be JSON-encoded"))
        }
        // Header
        guard 
            let (dimensions, _, rawElementType) = buffer.readMultipleIntegers(endianness: .big, as: (Int32, Int32, UInt32).self),
            0 <= dimensions, dimensions <= 1
        else {
            throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Malformed array header for PSQL type \(self.cell.dataType)"))
        }
        let elementType = PostgresDataType(rawElementType)
        guard dimensions == 1 else {
            return ArrayContainer(cells: [], decoder: self)
        }
        // One dimension: element count, then lower bound (always 1)
        guard 
            let (count, _) = buffer.readMultipleIntegers(endianness: .big, as: (Int32, Int32).self), 
            count >= 0 
        else {
            throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Malformed array dimensions for PSQL type \(self.cell.dataType)"))
        }

        // Elements        
        var cells: [PostgresCell] = []
        cells.reserveCapacity(Int(count))

        for index in 0..<Int(count) {
            guard let length = buffer.readInteger(as: Int32.self) else {
                throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Truncated array element \(index)"))
            }
            let bytes: ByteBuffer?
            if length == -1 {
                bytes = nil
            } else {
                guard let slice = buffer.readSlice(length: Int(length)) else {
                    throw DecodingError.dataCorrupted(.init(codingPath: self.codingPath, debugDescription: "Truncated array element \(index)"))
                }
                bytes = slice
            }
            cells.append(PostgresCell(
                bytes: bytes, dataType: elementType, format: .binary, columnName: self.cell.columnName, columnIndex: self.cell.columnIndex
            ))
        }

        return ArrayContainer(cells: cells, decoder: self)
    }

    func singleValueContainer() throws -> any SingleValueDecodingContainer { self }

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
        case indexed(ArrayRef<(any PostgresThrowingDynamicTypeEncodable)?>)
        case scalar((any PostgresThrowingDynamicTypeEncodable)?)

        var isValid: Bool { if case .invalid = self { return false }; return true }

        mutating func store(scalar: (any PostgresThrowingDynamicTypeEncodable)?) {
            if case .invalid = self { self = .scalar(scalar) } // no existing value, store the incoming
            else { preconditionFailure("Invalid request for multiple containers from the same encoder.") }
        }

        mutating func requestIndexed() {
            switch self {
            case .scalar(_): preconditionFailure("Invalid request for both single-value and unkeyed containers from the same encoder.")
            case .invalid: self = .indexed(.init()) // no existing value, make new array
            case .indexed(_): break  // existing array, adopt it for appending (support for superEncoder())
            }
        }

        var indexedCount: Int {
            if case .indexed(let ref) = self {
                return ref.contents.count
            }
            else { preconditionFailure("Internal error in encoder (requested indexed count from non-indexed state)") }
        }

        mutating func store(indexedScalar: (any PostgresThrowingDynamicTypeEncodable)?) {
            if case .indexed(let ref) = self {
                ref.contents.append(indexedScalar)
            }
            else { preconditionFailure("Internal error in encoder (attempted store to indexed in non-indexed state)") }
        }
    }

    var codingPath: [any CodingKey]
    let userInfo: [CodingUserInfoKey: Any]
    let context: PostgresEncodingContext<E>
    let file: String, line: Int
    var value: Value

    init(codingPath: [any CodingKey], userInfo: [CodingUserInfoKey: Any], context: PostgresEncodingContext<E>, file: String, line: Int, value: Value = .invalid) {
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

    func unkeyedContainer() -> any UnkeyedEncodingContainer {
        self.value.requestIndexed()
        return ArrayContainer(encoder: self)
    }

    func singleValueContainer() -> any SingleValueEncodingContainer {
        precondition(!self.value.isValid, "Requested multiple containers from the same encoder.")
        return self
    }

    struct ArrayContainer: UnkeyedEncodingContainer {
        let encoder: ArrayAwareBoxWrappingPostgresEncoder
        var codingPath: [any CodingKey] { self.encoder.codingPath }
        var count: Int { self.encoder.value.indexedCount }
        mutating func encodeNil() throws { self.encoder.value.store(indexedScalar: nil) }
        mutating func encode<T: Encodable>(_ value: T) throws {
            self.encoder.value.store(indexedScalar: try PostgresDataTranslation.encode(
                codingPath: self.codingPath + [SomeCodingKey(intValue: self.count)], userInfo: self.encoder.userInfo,
                value: value, in: self.encoder.context,
                file: self.encoder.file, line: self.encoder.line
            ))
        }
        mutating func nestedContainer<K: CodingKey>(keyedBy: K.Type) -> KeyedEncodingContainer<K> { self.superEncoder().container(keyedBy: K.self) }
        mutating func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer { self.superEncoder().unkeyedContainer() }
        mutating func superEncoder() -> any Encoder { ArrayAwareBoxWrappingPostgresEncoder(
            codingPath: self.codingPath + [SomeCodingKey(intValue: self.count)], userInfo: self.encoder.userInfo,
            context: self.encoder.context,
            file: self.encoder.file, line: self.encoder.line,
            value: self.encoder.value
        ) } // NOT the same as self.encoder
    }

    func encodeNil() throws {
        self.value.store(scalar: nil)
    }
    func encode<T: Encodable>(_ value: T) throws {
        self.value.store(scalar: try PostgresDataTranslation.encode(
            codingPath: self.codingPath, userInfo: self.userInfo, value: value, in: self.context, file: self.file, line: self.line
        ))
    }

    struct FallbackSentinel: Error {}

    /// This is a workaround for the inability of encoders to throw errors in various places. It's still better than fatalError()ing.
    struct FailureEncoder<K: CodingKey>: Encoder, KeyedEncodingContainerProtocol, UnkeyedEncodingContainer, SingleValueEncodingContainer {
        let codingPath = [any CodingKey](), userInfo = [CodingUserInfoKey: Any](), count = 0
        init() {}; init() where K == SomeCodingKey {}
        func encodeNil() throws { throw FallbackSentinel() }
        func encodeNil(forKey: K) throws { throw FallbackSentinel() }
        func encode<T: Encodable>(_: T) throws { throw FallbackSentinel() }
        func encode<T: Encodable>(_: T, forKey: K) throws { throw FallbackSentinel() }
        func nestedContainer<N: CodingKey>(keyedBy: N.Type) -> KeyedEncodingContainer<N> { .init(FailureEncoder<N>()) }
        func nestedContainer<N: CodingKey>(keyedBy: N.Type, forKey: K) -> KeyedEncodingContainer<N> { .init(FailureEncoder<N>()) }
        func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer { self }
        func nestedUnkeyedContainer(forKey: K) -> any UnkeyedEncodingContainer { self }
        func superEncoder() -> any Encoder { self }
        func superEncoder(forKey: K) -> any Encoder { self }
        func container<N: CodingKey>(keyedBy: N.Type) -> KeyedEncodingContainer<N> { .init(FailureEncoder<N>()) }
        func unkeyedContainer() -> any UnkeyedEncodingContainer { self }
        func singleValueContainer() -> any SingleValueEncodingContainer { self }
    }
}

// Taken from PostgresNIO 1.33.0, which does not make this useful data public.
extension PostgresDataType {
    var psqlkit_elementType: PostgresDataType? {
        switch self {
        case .xmlArray: .xml                       case .jsonArray: .json                     case .xid8Array: .xid8
        case .lineArray: .line                     case .cidrArray: .cidr                     case .circleArray: .circle
        case .macaddr8Array: .macaddr8             case .moneyArray: .money                   case .int2vectorArray: .int2vector
        case .regprocArray: .regproc               case .tidArray: .tid                       case .xidArray: .xid
        case .cidArray: .cid                       case .oidvectorArray: .oidvector           case .bpcharArray: .bpchar
        case .lsegArray: .lseg                     case .pathArray: .path                     case .boxArray: .box
        case .polygonArray: .polygon               case .oidArray: .oid                       case .aclitemArray: .aclitem
        case .macaddrArray: .macaddr               case .inetArray: .inet                     case .timestampArray: .timestamp
        case .dateArray: .date                     case .timeArray: .time                     case .timestamptzArray: .timestamptz
        case .intervalArray: .interval             case .numericArray: .numeric               case .cstringArray: .cstring
        case .timetzArray: .timetz                 case .bitArray: .bit                       case .varbitArray: .varbit
        case .refcursorArray: .refcursor           case .regprocedureArray: .regprocedure     case .regoperArray: .regoper
        case .regoperatorArray: .regoperator       case .regclassArray: .regclass             case .regtypeArray: .regtype
        case .recordArray: .record                 case .pgLSNArray: .pgLSN                   case .tsvectorArray: .tsvector
        case .gtsvectorArray: .gtsvector           case .tsqueryArray: .tsquery               case .regconfigArray: .regconfig
        case .regdictionaryArray: .regdictionary   case .numrangeArray: .numrange             case .tsrangeArray: .tsrange
        case .tstzrangeArray: .tstzrange           case .daterangeArray: .daterange           case .jsonpathArray: .jsonpath
        case .regnamespaceArray: .regnamespace     case .regroleArray: .regrole               case .regcollationArray: .regcollation
        case .int4multirangeArray: .int4multirange case .tsmultirangeArray: .tsmultirange     case .tstzmultirangeArray: .tstzmultirange
        case .datemultirangeArray: .datemultirange case .int8multirangeArray: .int8multirange case .boolArray: .bool
        case .byteaArray: .bytea                   case .charArray: .char                     case .nameArray: .name
        case .int2Array: .int2                     case .int4Array: .int4                     case .int8Array: .int8
        case .pointArray: .point                   case .float4Array: .float4                 case .float8Array: .float8
        case .uuidArray: .uuid                     case .jsonbArray: .jsonb                   case .textArray: .text
        case .varcharArray: .varchar               case .int4RangeArray: .int4Range           case .int8RangeArray: .int8Range
        default: nil
        }
    }

    var psqlkit_arrayType: PostgresDataType? {
        switch self {
        case .xml: .xmlArray
        case .json: .jsonArray
        case .xid8:  .xid8Array
        case .line: .lineArray
        case .cidr: .cidrArray
        case .circle: .circleArray
        case .macaddr8: .macaddr8Array
        case .money: .moneyArray
        case .int2vector: .int2vectorArray
        case .regproc: .regprocArray
        case .tid: .tidArray
        case .xid: .xidArray
        case .cid: .cidArray
        case .oidvector: .oidvectorArray
        case .bpchar: .bpcharArray
        case .lseg: .lsegArray
        case .path: .pathArray
        case .box: .boxArray
        case .polygon: .polygonArray
        case .oid: .oidArray
        case .aclitem: .aclitemArray
        case .macaddr: .macaddrArray
        case .inet: .inetArray
        case .timestamp: .timestampArray
        case .date: .dateArray
        case .time: .timeArray
        case .timestamptz: .timestamptzArray
        case .interval: .intervalArray
        case .numeric: .numericArray
        case .cstring: .cstringArray
        case .timetz: .timetzArray
        case .bit: .bitArray
        case .varbit: .varbitArray
        case .refcursor: .refcursorArray
        case .regprocedure: .regprocedureArray
        case .regoper: .regoperArray
        case .regoperator: .regoperatorArray
        case .regclass: .regclassArray
        case .regtype: .regtypeArray
        case .record: .recordArray
        case .pgLSN: .pgLSNArray
        case .tsvector: .tsvectorArray
        case .gtsvector: .gtsvectorArray
        case .tsquery: .tsqueryArray
        case .regconfig: .regconfigArray
        case .regdictionary: .regdictionaryArray
        case .numrange: .numrangeArray
        case .tsrange: .tsrangeArray
        case .tstzrange: .tstzrangeArray
        case .daterange: .daterangeArray
        case .jsonpath: .jsonpathArray
        case .regnamespace: .regnamespaceArray
        case .regrole: .regroleArray
        case .regcollation: .regcollationArray
        case .int4multirange: .int4multirangeArray
        case .tsmultirange: .tsmultirangeArray
        case .tstzmultirange: .tstzmultirangeArray
        case .datemultirange: .datemultirangeArray
        case .int8multirange: .int8multirangeArray
        case .bool: .boolArray
        case .bytea: .byteaArray
        case .char: .charArray
        case .name: .nameArray
        case .int2: .int2Array
        case .int4: .int4Array
        case .int8: .int8Array
        case .point: .pointArray
        case .float4: .float4Array
        case .float8: .float8Array
        case .uuid: .uuidArray
        case .jsonb: .jsonbArray
        case .text: .textArray
        case .varchar: .varcharArray
        case .int4Range: .int4RangeArray
        case .int8Range: .int8RangeArray
        default: nil
        }
    }
}
