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
            let context = _Context()
			try value.encode(to: _Encoder(codingPath: [], context: context))
            if let value = context.value {
                return value
            } else if let array = context.array {
                let elementType = array.first?.type ?? .jsonb
                assert(array.filter { $0.type != elementType }.isEmpty, "Array does not contain all: \(elementType)")
                return PostgresData(array: array, elementType: elementType)
            } else {
                return try PostgresData(jsonb: self.json.encode(_Wrapper(value)))
            }
        }
    }

    final class _Context {
        var value: PostgresData?
        var array: [PostgresData]?

        init() { }
    }

    struct _Encoder: Encoder, _SpecialEncoder {
        var userInfo: [CodingUserInfoKey : Any] {
            [:]
        }
		var impl: _Encoder {
			self
		}

        let codingPath: [CodingKey]
        let context: _Context

        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key>
            where Key : CodingKey
        {
            .init(_KeyedEncodingContainer<Key>(impl: self, codingPath: codingPath))
        }

        func unkeyedContainer() -> UnkeyedEncodingContainer {
            self.context.array = []
			return _UnkeyedEncodingContainer(impl: self, codingPath: self.codingPath, context: self.context)
        }

        func singleValueContainer() -> SingleValueEncodingContainer {
            _ValueContainer(context: self.context)
        }
    }

	struct _UnkeyedEncodingContainer: UnkeyedEncodingContainer, _SpecialEncoder {
		let impl: PostgresDataEncoder._Encoder

        let codingPath: [CodingKey]

        var count: Int {
            0
        }

        var context: _Context

        func encodeNil() throws {
            self.context.array!.append(.null)
        }

        func encode<T>(_ value: T) throws where T : Encodable {
            try self.context.array!.append(PostgresDataEncoder().encode(value))
        }

        func nestedContainer<NestedKey>(
            keyedBy keyType: NestedKey.Type
        ) -> KeyedEncodingContainer<NestedKey>
            where NestedKey : CodingKey
        {
			let newPath = self.codingPath + [_PostgresJSONKey(index: self.count)]
			let nestedContainer = _KeyedEncodingContainer<NestedKey>(impl: impl, codingPath: newPath)
			return KeyedEncodingContainer(nestedContainer)
        }

        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
			let newPath = self.codingPath + [_PostgresJSONKey(index: self.count)]
			let nestedContainer = _UnkeyedEncodingContainer(impl: impl, codingPath: newPath, context: context)
			return nestedContainer
        }

        func superEncoder() -> Encoder {
			let encoder = self.getEncoder(for: _PostgresJSONKey(index: self.count))
			return encoder
        }
    }

    struct _KeyedEncodingContainer<Key>: KeyedEncodingContainerProtocol, _SpecialEncoder
        where Key: CodingKey
	{
		let impl: PostgresDataEncoder._Encoder

        let codingPath: [CodingKey]

        func encodeNil(forKey key: Key) throws {
            // do nothing
        }

        func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            // do nothing
        }

        func nestedContainer<NestedKey>(
            keyedBy keyType: NestedKey.Type,
            forKey key: Key
        ) -> KeyedEncodingContainer<NestedKey>
            where NestedKey : CodingKey
        {
			let newPath = self.codingPath + [key]
			let nestedContainer = _KeyedEncodingContainer<NestedKey>(impl: impl, codingPath: newPath)
			return KeyedEncodingContainer(nestedContainer)
        }

        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
			let newPath = self.codingPath + [key]
			let nestedContainer = _UnkeyedEncodingContainer(impl: impl, codingPath: newPath, context: .init())
			return nestedContainer
        }

        func superEncoder() -> Encoder {
			superEncoder(forKey: .init(stringValue: "super")!)
        }

        func superEncoder(forKey key: Key) -> Encoder {
			let newEncoder = self.getEncoder(for: key)
			// self.object.set(newEncoder, for: convertedKey.stringValue)
			return newEncoder
		}
    }


    struct _ValueContainer: SingleValueEncodingContainer {
        var codingPath: [CodingKey] {
            []
        }
        let context: _Context

        func encodeNil() throws {
            self.context.value = .null
        }

        func encode<T>(_ value: T) throws where T : Encodable {
            self.context.value = try PostgresDataEncoder().encode(value)
        }
    }

    struct _Wrapper: Encodable {
        let encodable: Encodable
        init(_ encodable: Encodable) {
            self.encodable = encodable
        }
        func encode(to encoder: Encoder) throws {
            try self.encodable.encode(to: encoder)
        }
    }
}

internal struct _PostgresJSONKey: CodingKey {
	public var stringValue: String
	public var intValue: Int?

	public init?(stringValue: String) {
		self.stringValue = stringValue
		self.intValue = nil
	}

	public init?(intValue: Int) {
		self.stringValue = "\(intValue)"
		self.intValue = intValue
	}

	public init(stringValue: String, intValue: Int?) {
		self.stringValue = stringValue
		self.intValue = intValue
	}

	internal init(index: Int) {
		self.stringValue = "Index \(index)"
		self.intValue = index
	}

	internal static let `super` = _PostgresJSONKey(stringValue: "super")!
}

///
private protocol _SpecialEncoder {
	/// The coding path of the encoder.
	var codingPath: [CodingKey] { get }
	/// The associated `PostgresDataEncoder._Encoder` object.
	var impl: PostgresDataEncoder._Encoder { get }
}


extension _SpecialEncoder {
	fileprivate func getEncoder(for additionalKey: CodingKey?) -> PostgresDataEncoder._Encoder {
		if let additionalKey = additionalKey {
			var newCodingPath = self.codingPath
			newCodingPath.append(additionalKey)
			return PostgresDataEncoder._Encoder(codingPath: newCodingPath, context: .init())
		}

		return self.impl
	}
}
