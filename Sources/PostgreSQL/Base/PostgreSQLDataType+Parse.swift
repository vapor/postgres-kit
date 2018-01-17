import Foundation

extension PostgreSQLDataType {
    /// Parses this column to the specified data type and format code.
    func parse(_ data: Data, format: PostgreSQLFormatCode) throws -> PostgreSQLData {
        switch format {
        case .text: return try parseText(from: data)
        case .binary: return try parseBinary(from: data)
        }
    }

    /// Parses this column to the specified data type assuming binary format.
    private func parseBinary(from data: Data) throws -> PostgreSQLData {
        switch self {
        case .name, .text, .varchar: return try .string(data.makeString())
        case .int8: return .int(data.makeFixedWidthInteger())
        case .oid, .regproc, .int4: return .int32(data.makeFixedWidthInteger())
        case .int2: return .int16(data.makeFixedWidthInteger())
        case .bool, .char: return .uint8(data.makeFixedWidthInteger())
        case .bytea: return .data(data)
        case .void: return .null
        case .float4: return .float(data.makeFloatingPoint())
        case .float8: return .double(data.makeFloatingPoint())
        case .bpchar: return try .string(data.makeString())
        case .timestamp, .date, .time, .numeric, .pg_node_tree, ._aclitem:
            fatalError("Unexpected binary for \(self) (preferred format): \(data.hexDebug)")
        }
    }

    /// Parses this column to the specified data type assuming text format.
    private func parseText(from data: Data) throws -> PostgreSQLData {
        switch self {
        case .bool: return try .uint8(data.makeString() == "t" ? 1 : 0)
        case .text, .name, .varchar, .bpchar: return try .string(data.makeString())
        case .int8: return try Int(data.makeString()).flatMap { .int($0) } ?? .null
        case .oid, .regproc, .int4: return try Int32(data.makeString()).flatMap { .int32($0) } ?? .null
        case .int2: return try Int16(data.makeString()).flatMap { .int16($0) } ?? .null
        case .char: return .uint8(data[0])
        case .float4: return try Float(data.makeString()).flatMap { .float($0) } ?? .null
        case .numeric, .float8: return try Double(data.makeString()).flatMap { .double($0) } ?? .null
        case .bytea: return try data.makeString().hexadecimal().flatMap { .data($0) } ?? .null
        case .timestamp: return try .date(data.makeString().parseDate(format:  "yyyy-MM-dd HH:mm:ss"))
        case .date: return try .date(data.makeString().parseDate(format:  "yyyy-MM-dd"))
        case .time: return try .date(data.makeString().parseDate(format:  "HH:mm:ss"))
        case .void: return .null
        case .pg_node_tree, ._aclitem: return try .string(data.makeString())
        }
    }
}



/// MARK: Data Helpers

extension Data {
    /// Converts this data to a floating-point number.
    fileprivate func makeFloatingPoint<F>(_ type: F.Type = F.self) -> F where F: FloatingPoint {
        return Data(reversed()).withUnsafeBytes { (pointer: UnsafePointer<F>) -> F in
            return pointer.pointee
        }
    }

    /// Converts this data to a fixed-width integer.
    fileprivate func makeFixedWidthInteger<I>(_ type: I.Type = I.self) -> I where I: FixedWidthInteger {
        return withUnsafeBytes { (pointer: UnsafePointer<I>) -> I in
            return pointer.pointee.bigEndian
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
        guard let date = formatter.date(from: self) else {
            throw PostgreSQLError(identifier: "date", reason: "Malformed date: \(self)")
        }
        return date
    }

    /// Create `Data` from hexadecimal string representation
    ///
    /// This takes a hexadecimal representation and creates a `Data` object. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    ///
    /// - returns: Data represented by this hexadecimal string.
    /// https://stackoverflow.com/questions/26501276/converting-hex-string-to-nsdata-in-swift
    fileprivate func hexadecimal() -> Data? {
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

