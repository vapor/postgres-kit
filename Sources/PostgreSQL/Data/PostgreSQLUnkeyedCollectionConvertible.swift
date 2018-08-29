import Foundation

/// Sub-protocol of `PostgreSQLDataConvertible` for unkeyed collection types (like arrays and sets).
public protocol PostgreSQLUnkeyedCollectionConvertible: PostgreSQLDataConvertible {
    /// The type of the element associated with this collection.
    associatedtype PostgreSQLCollectionElement
    /// Initializes this collection from an array of values.
    static func convertFromPostgreSQLArray(_ data: [PostgreSQLCollectionElement]) -> Self
    /// Converts this collection into an array of values.
    func convertToPostgreSQLArray() -> [PostgreSQLCollectionElement]
}

extension PostgreSQLUnkeyedCollectionConvertible {
    /// See `PostgreSQLDataConvertible`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        guard let convertible = PostgreSQLCollectionElement.self as? PostgreSQLDataConvertible.Type else {
            throw PostgreSQLError(identifier: "array", reason: "Cannot decode array value for \(PostgreSQLCollectionElement.self)")
        }

        let array = try extractPostgreSQLArrayValues(from: data)
        let psqlArray = try array.map { (data) -> PostgreSQLCollectionElement in
            return try convertible.convertFromPostgreSQLData(data) as! PostgreSQLCollectionElement
        }

        return convertFromPostgreSQLArray(psqlArray)
    }

    /// Extracts the array values from the given data (assuming it's an array) and returns
    /// an array of `PostgreSQLData` values.
    public static func extractPostgreSQLArrayValues(from data: PostgreSQLData) throws -> [PostgreSQLData] {
        guard case .binary(var value) = data.storage else {
            throw PostgreSQLError(identifier: "nullArray", reason: "Unable to decode PostgreSQL array from `null` data.")
        }

        var array = [PostgreSQLData]()
        let hasData = value.extract(Int32.self).bigEndian
        if hasData == 1 {
            /// Unknown
            let _ = value.extract(Int32.self).bigEndian
            /// The big-endian array element type
            let type: PostgreSQLDataFormat = .init(value.extract(Int32.self).bigEndian)
            /// The big-endian length of the array
            let count = value.extract(Int32.self).bigEndian
            /// The big-endian number of dimensions
            let _ = value.extract(Int32.self).bigEndian
            for _ in 0..<count {
                let count = Int(value.extract(Int32.self).bigEndian)
                let data = PostgreSQLData(type, binary: value.extract(count: count))
                array.append(data)
            }
        }

        return array
    }

    /// See `PostgreSQLDataConvertible`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        let elements = try convertToPostgreSQLArray().map { (value) -> PostgreSQLData in
            guard let newValue = value as? PostgreSQLDataConvertible else {
                throw PostgreSQLError(identifier: "array",
                                      reason: "\(PostgreSQLCollectionElement.self) does not conform to `PostgreSQLDataConvertible`")
            }

            return try newValue.convertToPostgreSQLData()
        }

        let type: PostgreSQLDataFormat
        if let elementType = PostgreSQLCollectionElement.self as? PostgreSQLDataTypeStaticRepresentable.Type,
           let format = elementType.postgreSQLDataType.dataFormat
        {
            type = format
        } else {
            WARNING("Could not determine PostgreSQL array data type: \(PostgreSQLCollectionElement.self)")
            type = .null
        }

        var data = Data()
        data += Data.of(Int32(1).bigEndian)                 // non-null
        data += Data.of(Int32(0).bigEndian)                 // b
        data += Data.of(type.raw.bigEndian)
        data += Data.of(Int32(elements.count).bigEndian)    // length
        data += Data.of(Int32(1).bigEndian)                 // dimensions

        for element in elements {
            switch element.storage {
                case .binary(let value):
                    data += Data.of(Int32(value.count).bigEndian)
                    data += value
                default:
                    data += Data.of(Int32(0).bigEndian)
            }
        }

        return PostgreSQLData(type.arrayType ?? .null, binary: data)
    }
}

extension Array: PostgreSQLUnkeyedCollectionConvertible {
    /// See `PostgreSQLUnkeyedCollectionConvertible`
    public typealias PostgreSQLCollectionElement = Element

    /// See `PostgreSQLUnkeyedCollectionConvertible`
    public static func convertFromPostgreSQLArray(_ data: [PostgreSQLCollectionElement]) -> Array {
        return data
    }

    /// See `PostgreSQLUnkeyedCollectionConvertible`
    public func convertToPostgreSQLArray() -> [PostgreSQLCollectionElement] {
        return self
    }
}
