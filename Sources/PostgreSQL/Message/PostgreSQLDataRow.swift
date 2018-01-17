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

    /// Parses this column to the specified data type and format code.
    func parse(dataType: PostgreSQLDataType, format: PostgreSQLFormatCode) throws -> PostgreSQLData {
        switch format {
        case .text: return try parseText(dataType: dataType)
        case .binary: return try parseBinary(dataType: dataType)
        }
    }

    /// Parses this column to the specified data type assuming binary format.
    func parseBinary(dataType: PostgreSQLDataType) throws -> PostgreSQLData {
        guard let value = self.value else { return .null }

        switch dataType {
        case .name, .text, .varchar: return try .string(value.makeString())
        case .int8: return .int(value.makeFixedWidthInteger())
        case .oid, .regproc, .int4: return .int32(value.makeFixedWidthInteger())
        case .int2: return .int16(value.makeFixedWidthInteger())
        case .bool, .char: return .uint8(value.makeFixedWidthInteger())
        case .bytea: return .data(value)
        case .bpchar, .timestamp, .date, .time:
            fatalError("\(dataType): \(value.hexDebug)")
        case .float4:
            fatalError("float4: \(value.hexDebug)")
        case .float8:
            fatalError("float8: \(value.hexDebug)")
        case .numeric:
            fatalError("numeric: \(value.hexDebug)")
        case .pg_node_tree:
            print("pg node tree")
            return .null
        case ._aclitem:
            print("acl item")
            return .null
        case .void: return .null
        }
    }

    /// Parses this column to the specified data type assuming text format.
    func parseText(dataType: PostgreSQLDataType) throws -> PostgreSQLData {
        guard let value = self.value else { return .null }
        switch dataType {
        case .bool:
            let bool = try value.makeString() == "t"
            return .uint8(bool ? 1 : 0)
        case .text, .name, .varchar, .bpchar: return try .string(value.makeString())
        case .int8: return try Int(value.makeString()).flatMap { .int($0) } ?? .null
        case .oid, .regproc, .int4: return try Int32(value.makeString()).flatMap { .int32($0) } ?? .null
        case .int2: return try Int16(value.makeString()).flatMap { .int16($0) } ?? .null
        case .char: return .uint8(value[0])
        case .float4: return try Float(value.makeString()).flatMap { .float($0) } ?? .null
        case .numeric, .float8: return try Double(value.makeString()).flatMap { .double($0) } ?? .null
        case .bytea: return try value.makeString().hexadecimal().flatMap { .data($0) } ?? .null
        case .timestamp:
            let string = try value.makeString()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
            let date = formatter.date(from: string) !! "Malformed timestamp: \(string)"
            return .date(date)
        case .date:
            let string = try value.makeString()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let date = formatter.date(from: string) !! "Malformed date: \(string)"
            return .date(date)
        case .time:
            let string = try value.makeString()
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSSSSS"
            let date = formatter.date(from: string) !! "Malformed time: \(string)"
            return .date(date)
        case .void: return .null
        case .pg_node_tree:
            print("pg node tree")
            return .null
        case ._aclitem:
            print("acl item")
            return .null
        }
//        print(String(data: value, encoding: .utf8))
//        fatalError("\(dataType): \(value.hexDebug)")
    }
}

extension Data {
    func makeFixedWidthInteger<I>(_ type: I.Type = I.self) -> I where I: FixedWidthInteger {
        return withUnsafeBytes { (pointer: UnsafePointer<I>) -> I in
            return pointer.pointee.bigEndian
        }
    }

    /// Convert the row's data into a string, throwing if invalid encoding.
    func makeString(encoding: String.Encoding = .utf8) throws -> String {
        guard let string = String(data: self, encoding: encoding) else {
            throw PostgreSQLError(identifier: "utf8String", reason: "Unexpected non-UTF8 string.")
        }

        return string
    }
}

extension String {
    /// Create `Data` from hexadecimal string representation
    ///
    /// This takes a hexadecimal representation and creates a `Data` object. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    ///
    /// - returns: Data represented by this hexadecimal string.

    func hexadecimal() -> Data? {
        var data = Data(capacity: count / 2)

        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSMakeRange(0, utf16.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }

        guard data.count > 0 else { return nil }

        return data
    }

}
