import Foundation

public protocol PostgreSQLUnkeyedCollectionConvertible: PostgreSQLDataConvertible {

    associatedtype PostgreSQLCollectionElement

    static func convertFromPostgreSQLArray(_ data: [PostgreSQLCollectionElement]) -> Self

    func convertToPostgreSQLArray() -> [PostgreSQLCollectionElement]
}

extension PostgreSQLUnkeyedCollectionConvertible {

    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        fatalError()
    }

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

    public typealias PostgreSQLCollectionElement = Element

    public static func convertFromPostgreSQLArray(_ data: [PostgreSQLCollectionElement]) -> Array {
        return data
    }

    public func convertToPostgreSQLArray() -> [PostgreSQLCollectionElement] {
        return self
    }
}
