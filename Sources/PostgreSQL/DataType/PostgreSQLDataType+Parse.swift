import Foundation

extension PostgreSQLDataType {
//    /// Parses this column to the specified data type and format code.
//    func parse(_ data: Data, format: PostgreSQLFormatCode) throws -> PostgreSQLData {
//        return Postgre
//        switch format {
//        case .text: return try parseText(from: data)
//        case .binary: return try parseBinary(from: data)
//        }
//    }

//    /// Parses this column to the specified data type assuming binary format.
//    private func parseBinary(from data: Data) throws -> PostgreSQLData {
//        switch self {
//        case .name, .text, .varchar: return try .string(data.makeString())
//        case .int8: return .int64(data.makeFixedWidthInteger())
//        case .oid, .regproc, .int4: return .int32(data.makeFixedWidthInteger())
//        case .int2: return .int16(data.makeFixedWidthInteger())
//        case .bool, .char: return .int8(data.makeFixedWidthInteger())
//        case .bytea: return .data(data)
//        case .void: return .null
//        case .float4: return .float(data.makeFloatingPoint())
//        case .float8: return .double(data.makeFloatingPoint())
//        case .bpchar: return try .string(data.makeString())
//        case .point: return .point(x: data[0..<8].makeFloatingPoint(), y: data[8..<16].makeFloatingPoint())
//        case .uuid: return .uuid(UUID(uuid: data.unsafeCast()))
//        case .timestamp, .date, .time, .numeric, .pg_node_tree, ._aclitem:
//            throw PostgreSQLError(identifier: "dataType", reason: "Unsupported data type during parse binary: \(self)")
//        default:
//            throw PostgreSQLError(identifier: "dataType", reason: "Unrecognized data type during parse binary: \(self)")
//        }
//    }
//
//    /// Parses this column to the specified data type assuming text format.
//    private func parseText(from data: Data) throws -> PostgreSQLData {
//        switch self {
//        case .bool: return try .int8(data.makeString() == "t" ? 1 : 0)
//        case .text, .name, .varchar, .bpchar,.numeric: return try .string(data.makeString())
//        case .int8: return try Int64(data.makeString()).flatMap { .int64($0) } ?? .null
//        case .oid, .regproc, .int4: return try Int32(data.makeString()).flatMap { .int32($0) } ?? .null
//        case .int2: return try Int16(data.makeString()).flatMap { .int16($0) } ?? .null
//        case .char: return .int8(Int8(bitPattern: data[0]))
//        case .float4: return try Float(data.makeString()).flatMap { .float($0) } ?? .null
//        case .float8: return try Double(data.makeString()).flatMap { .double($0) } ?? .null
//        case .bytea: return try .data(Data(hexString: data[2...].makeString()))
//        case .timestamp: return try .date(data.makeString().parseDate(format:  "yyyy-MM-dd HH:mm:ss"))
//        case .date: return try .date(data.makeString().parseDate(format:  "yyyy-MM-dd"))
//        case .time: return try .date(data.makeString().parseDate(format:  "HH:mm:ss"))
//        case .void: return .null
//        case .point:
//            let string = try data.makeString()
//            let parts = string.split(separator: ",")
//            var x = parts[0]
//            var y = parts[1]
//            assert(x.popFirst()! == "(")
//            assert(y.popLast()! == ")")
//            return .point(x: Double(x)!, y: Double(y)!)
//        case .pg_node_tree, ._aclitem: return try .string(data.makeString())
//        case .jsonb, .json: return try JSONDecoder().decode(PostgreSQLData.self, from: data)
//        default:
//            throw PostgreSQLError(identifier: "dataType", reason: "Unrecognized data type during parse text: \(self)")
//        }
//    }
}



/// MARK: Data Helpers

extension Data {
    /// Converts this data to a floating-point number.
    fileprivate func makeFloatingPoint<F>(_ type: F.Type = F.self) -> F where F: FloatingPoint {
        return Data(reversed()).unsafeCast()
    }

    /// Converts this data to a fixed-width integer.
    fileprivate func makeFixedWidthInteger<I>(_ type: I.Type = I.self) -> I where I: FixedWidthInteger {
        return unsafeCast(to: I.self).bigEndian
    }

    fileprivate func unsafeCast<T>(to type: T.Type = T.self) -> T {
        return withUnsafeBytes { (pointer: UnsafePointer<T>) -> T in
            return pointer.pointee
        }
    }

    /// Convert the row's data into a string, throwing if invalid encoding.
    fileprivate func makeString(encoding: String.Encoding = .utf8) throws -> String {
        guard let string = String(data: self, encoding: encoding) else {
            throw PostgreSQLError(identifier: "utf8String", reason: "Unexpected non-UTF8 string.")
        }

        return string
    }
}

/// MARK: String Helpers

extension String {
    /// Parses a Date from this string with the supplied date format.
    fileprivate func parseDate(format: String) throws -> Date {
        let formatter = DateFormatter()
        if contains(".") {
            formatter.dateFormat = format + ".SSSSSS"
        } else {
            formatter.dateFormat = format
        }
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        guard let date = formatter.date(from: self) else {
            throw PostgreSQLError(identifier: "date", reason: "Malformed date: \(self)")
        }
        return date
    }
}

extension Data {
    /// Initialize data from a hex string.
    fileprivate init(hexString: String) {
        var data = Data()

        var gen = hexString.makeIterator()
        while let c1 = gen.next(), let c2 = gen.next() {
            let s = String([c1, c2])
            guard let d = UInt8(s, radix: 16) else {
                break
            }

            data.append(d)
        }

        self.init(data)
    }

}
