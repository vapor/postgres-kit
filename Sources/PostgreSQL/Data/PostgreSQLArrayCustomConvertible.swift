///// Representable by a `T[]` column on the PostgreSQL database.
//public protocol PostgreSQLArrayCustomConvertible: PostgreSQLDataConvertible {
//    /// The associated array element type
//    associatedtype PostgreSQLArrayElement // : PostgreSQLDataCustomConvertible
//
//    /// Convert an array of elements to self.
//    static func convertFromPostgreSQLArray(_ data: [PostgreSQLArrayElement]) -> Self
//
//    /// Convert self to an array of elements.
//    func convertToPostgreSQLArray() -> [PostgreSQLArrayElement]
//}
//
//extension PostgreSQLArrayCustomConvertible {
//    /// See `PostgreSQLDataConvertible`.
//    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
//        switch data.storage {
//        case .binary(var value):
//            /// Extract and convert each element.
//            var array: [PostgreSQLArrayElement] = []
//
//            let hasData = value.extract(Int32.self).bigEndian
//            if hasData == 1 {
//                /// grab the array metadata from the beginning of the data
//                let metadata = value.extract(PostgreSQLArrayMetadata.self)
//                for _ in 0..<metadata.count {
//                    let count = Int(value.extract(Int32.self).bigEndian)
//                    let subValue = value.extract(count: count)
//                    let psqlData = PostgreSQLData(metadata.type, binary: subValue)
//                    let element = try requirePostgreSQLDataCustomConvertible(PostgreSQLArrayElement.self).convertFromPostgreSQLData(psqlData)
//                    array.append(element as! PostgreSQLArrayElement)
//                }
//            } else {
//                array = []
//            }
//
//            return convertFromPostgreSQLArray(array)
//        default: throw PostgreSQLError(identifier: "nullArray", reason: "Unable to decode PostgreSQL array from null or text formatted data.")
//        }
//    }
//
//    /// See `PostgreSQLDataConvertible`.
//    public func convertToPostgreSQLData() throws -> PostgreSQLData {
//        let elements = try convertToPostgreSQLArray().map {
//            try requirePostgreSQLDataCustomConvertible($0).convertToPostgreSQLData()
//        }
//
//
//    }
//}
//
//private struct PostgreSQLArrayMetadata {
//    /// Unknown
//    private let _b: Int32
//
//    /// The big-endian array element type
//    private let _type: Int32
//
//    /// The big-endian length of the array
//    private let _count: Int32
//
//    /// The big-endian number of dimensions
//    private let _dimensions: Int32
//
//    /// Converts the raw array elemetn type to DataType
//    var type: PostgreSQLDataType {
//        return .init(_type.bigEndian)
//    }
//
//    /// The length of the array
//    var count: Int32 {
//        return _count.bigEndian
//    }
//
//    /// The  number of dimensions
//    var dimensions: Int32 {
//        return _dimensions.bigEndian
//    }
//}
//
//extension PostgreSQLArrayMetadata: CustomStringConvertible {
//    /// See `CustomStringConvertible`.
//    var description: String {
//        return "\(type)[\(count)]"
//    }
//}
//
//extension Array: PostgreSQLArrayCustomConvertible {
//    /// See `PostgreSQLDataCustomConvertible`.
//    public static var postgreSQLDataArrayType: PostgreSQLDataType {
//        fatalError("Multi-dimensional arrays are not yet supported.")
//    }
//
//    /// See `PostgreSQLDataCustomConvertible`.
//    public static var postgreSQLDataType: PostgreSQLDataType {
//        return requirePostgreSQLDataCustomConvertible(Element.self).postgreSQLDataArrayType
//    }
//
//    /// See `PostgreSQLArrayCustomConvertible`.
//    public typealias PostgreSQLArrayElement = Element
//
//    /// See `PostgreSQLArrayCustomConvertible`.
//    public static func convertFromPostgreSQLArray(_ data: [Element]) -> Array<Element> {
//        return data
//    }
//
//    /// See `PostgreSQLArrayCustomConvertible`.
//    public func convertToPostgreSQLArray() -> [Element] {
//        return self
//    }
//}
//
//func requirePostgreSQLDataCustomConvertible<T>(_ type: T.Type) -> PostgreSQLDataConvertible.Type {
//    guard let custom = T.self as? PostgreSQLDataConvertible.Type else {
//        fatalError("`\(T.self)` does not conform to `PostgreSQLDataCustomConvertible`")
//    }
//    return custom
//}
//
//func requirePostgreSQLDataCustomConvertible<T>(_ type: T) -> PostgreSQLDataConvertible {
//    guard let custom = type as? PostgreSQLDataConvertible else {
//        fatalError("`\(T.self)` does not conform to `PostgreSQLDataCustomConvertible`")
//    }
//    return custom
//}
