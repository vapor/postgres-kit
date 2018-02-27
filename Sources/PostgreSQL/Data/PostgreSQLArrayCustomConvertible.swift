import Foundation

/// Representable by a `T[]` column on the PostgreSQL database.
public protocol PostgreSQLArrayCustomConvertible: PostgreSQLDataCustomConvertible {
    /// The associated array element type
    associatedtype PostgreSQLArrayElement // : PostgreSQLDataCustomConvertible

    /// Convert an array of elements to self.
    static func convertFromPostgreSQLArray(_ data: [PostgreSQLArrayElement]) -> Self

    /// Convert self to an array of elements.
    func convertToPostgreSQLArray() -> [PostgreSQLArrayElement]
}

extension PostgreSQLArrayCustomConvertible {
    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        guard var value = data.data else {
            throw PostgreSQLError(identifier: "nullArray", reason: "Unable to decode PostgreSQL array from `null` data.", source: .capture())
        }

        /// Extract and convert each element.
        var array: [PostgreSQLArrayElement] = []

        let hasData = value.extract(Int32.self).bigEndian
        if hasData == 1 {
            /// grab the array metadata from the beginning of the data
            let metadata = value.extract(PostgreSQLArrayMetadata.self)
            for _ in 0..<metadata.count {
                let count = Int(value.extract(Int32.self).bigEndian)
                let subValue = value.extract(count: count)
                let psqlData = PostgreSQLData(type: metadata.type, format: data.format, data: subValue)
                let element = try requirePostgreSQLDataCustomConvertible(PostgreSQLArrayElement.self).convertFromPostgreSQLData(psqlData)
                array.append(element as! PostgreSQLArrayElement)
            }
        } else {
            array = []
        }

        return convertFromPostgreSQLArray(array)
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        let elements = try convertToPostgreSQLArray().map {
            try requirePostgreSQLDataCustomConvertible($0).convertToPostgreSQLData()
        }

        var data = Data()
        data += Int32(1).data // non-null
        data += Int32(0).data // b
        data += requirePostgreSQLDataCustomConvertible(PostgreSQLArrayElement.self).postgreSQLDataType.raw.data // type
        data += Int32(elements.count).data // length
        data += Int32(1).data // dimensions

        for element in elements {
            if let value = element.data {
                data += Int32(value.count).data
                data += value
            } else {
                data += Int32(0).data
            }
        }

        return PostgreSQLData(type: requirePostgreSQLDataCustomConvertible(PostgreSQLArrayElement.self).postgreSQLDataArrayType, format: .binary, data: data)
    }
}

fileprivate struct PostgreSQLArrayMetadata {
    /// Unknown
    private let _b: Int32

    /// The big-endian array element type
    private let _type: Int32

    /// The big-endian length of the array
    private let _count: Int32

    /// The big-endian number of dimensions
    private let _dimensions: Int32

    /// Converts the raw array elemetn type to DataType
    var type: PostgreSQLDataType {
        return .init(_type.bigEndian)
    }

    /// The length of the array
    var count: Int32 {
        return _count.bigEndian
    }

    /// The  number of dimensions
    var dimensions: Int32 {
        return _dimensions.bigEndian
    }
}

extension PostgreSQLArrayMetadata: CustomStringConvertible {
    /// See `CustomStringConvertible.description`
    var description: String {
        return "\(type)[\(count)]"
    }
}

extension Array: PostgreSQLArrayCustomConvertible {
    /// See `PostgreSQLArrayCustomConvertible.postgreSQLDataArrayType`
    public static var postgreSQLDataArrayType: PostgreSQLDataType {
        fatalError("Multi-dimensional arrays are not yet supported.")
    }

    /// See `PostgreSQLDataCustomConvertible.postgreSQLDataType`
    public static var postgreSQLDataType: PostgreSQLDataType {
        return requirePostgreSQLDataCustomConvertible(Element.self).postgreSQLDataArrayType
    }

    /// See `PostgreSQLArrayCustomConvertible.PostgreSQLArrayElement`
    public typealias PostgreSQLArrayElement = Element

    /// See `PostgreSQLArrayCustomConvertible.convertFromPostgreSQLArray(_:)`
    public static func convertFromPostgreSQLArray(_ data: [Element]) -> Array<Element> {
        return data
    }

    /// See `PostgreSQLArrayCustomConvertible.convertToPostgreSQLArray(_:)`
    public func convertToPostgreSQLArray() -> [Element] {
        return self
    }
}

func requirePostgreSQLDataCustomConvertible<T>(_ type: T.Type) -> PostgreSQLDataCustomConvertible.Type {
    guard let custom = T.self as? PostgreSQLDataCustomConvertible.Type else {
        fatalError("`\(T.self)` does not conform to `PostgreSQLDataCustomConvertible`")
    }
    return custom
}

func requirePostgreSQLDataCustomConvertible<T>(_ type: T) -> PostgreSQLDataCustomConvertible {
    guard let custom = type as? PostgreSQLDataCustomConvertible else {
        fatalError("`\(T.self)` does not conform to `PostgreSQLDataCustomConvertible`")
    }
    return custom
}
