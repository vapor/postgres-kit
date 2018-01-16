import Bits
import Foundation

/// Identifies the message as a data row.
struct PostgreSQLDataRow: Decodable {
    /// The data row's columns
    var columns: [PostgreSQLDataRowColumn]

    /// See Decodable.decode
    init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        /// The number of column values that follow (possibly zero).
        let count = try single.decode(Int16.self)

        var columns: [PostgreSQLDataRowColumn] = []
        for _ in 0..<count {
            let column = try single.decode(PostgreSQLDataRowColumn.self)
            columns.append(column)
        }
        self.columns = columns
    }
}

struct PostgreSQLDataRowColumn: Decodable {
    /// The length of the column value, in bytes (this count does not include itself).
    /// Can be zero. As a special case, -1 indicates a NULL column value. No value bytes follow in the NULL case.

    /// The value of the column, in the format indicated by the associated format code. n is the above length.
    var value: Data?

    /// Convert the row's data into a string, throwing if invalid encoding.
    func makeString(encoding: String.Encoding = .utf8) throws -> String? {
        return try value.flatMap { data in
            guard let string = String(data: data, encoding: encoding) else {
                throw PostgreSQLError(identifier: "utf8String", reason: "Unexpected non-UTF8 string.")
            }
            return string
        }
    }
    /// Parses this column to the specified data type and format code.
    func parse(dataType: PostgreSQLDataType, format: PostgreSQLFormatCode) throws -> PostgreSQLData {
        switch format {
        case .text: return try parseText(dataType: dataType)
        case .binary: return try parseBinary(dataType: dataType)
        }
    }

    /// Parses this column to the specified data type assuming binary format.
    func parseBinary(dataType: PostgreSQLDataType) throws -> PostgreSQLData {
        switch dataType {
        case .name, .text:
            return try makeString().flatMap { .string($0) } ?? .null
        case .oid, .regproc, .int4:
            return makeFixedWidthInteger(Int32.self).flatMap { .int32($0) } ?? .null
        case .int2:
            return makeFixedWidthInteger(Int16.self).flatMap { .int16($0) } ?? .null
        case .bool:
            return makeFixedWidthInteger(Byte.self).flatMap { .bool($0 == 1) } ?? .null
        case .char:
            return makeFixedWidthInteger(Byte.self).flatMap { byte in
                let char = Character(Unicode.Scalar(byte))
                return .character(char)
            } ?? .null
        case .pg_node_tree:
            print("pg node tree")
            return .null
        case ._aclitem:
            print("acl item")
            return .null
        }
    }

    func makeFixedWidthInteger<I>(_ type: I.Type = I.self) -> I? where I: FixedWidthInteger {
        return value.flatMap { data in
            return data.withUnsafeBytes { (pointer: UnsafePointer<I>) -> I in
                return pointer.pointee.bigEndian
            }
        }
    }

    /// Parses this column to the specified data type assuming text format.
    func parseText(dataType: PostgreSQLDataType) throws -> PostgreSQLData {
        let data: PostgreSQLData
        switch dataType {
        case .bool:
            data = try makeString().flatMap { $0 == "t" }.flatMap { .bool($0) } ?? .null
        case .text, .name:
            data = try makeString().flatMap { .string($0) } ?? .null
        case .oid, .regproc, .int4:
            data = try makeString().flatMap { Int32($0) }.flatMap { .int32($0) } ?? .null
        case .int2:
            data = try makeString().flatMap { Int16($0) }.flatMap { .int16($0) } ?? .null
        case .char:
            data = try makeString().flatMap { Character($0) }.flatMap { .character($0) } ?? .null
        case .pg_node_tree:
            print("pg node tree")
            data = .null
        case ._aclitem:
            print("acl item")
            data = .null
        }
        return data
    }
}
