import Foundation

extension String: PostgreSQLDataCustomConvertible {
    /// See `PostgreSQLDataCustomConvertible.preferredDataType`
    public static var preferredDataType: PostgreSQLDataType? { return .text }

    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> String {
        guard let value = data.data else {
            throw PostgreSQLError(identifier: "string", reason: "Could not decode String from `null` data.")
        }
        switch data.format {
        case .text:
            guard let string = String(data: value, encoding: .utf8) else {
                throw PostgreSQLError(identifier: "string", reason: "Non-UTF8 string: \(value.hexDebug).")
            }
            return string
        case .binary:
            switch data.type {
            case .text, .name, .varchar, .bpchar:
                guard let string = String(data: value, encoding: .utf8) else {
                    throw PostgreSQLError(identifier: "string", reason: "Non-UTF8 string: \(value.hexDebug).")
                }
                return string
            case .point:
                let point = try PostgreSQLPoint.convertFromPostgreSQLData(data)
                return point.description
            case .numeric:
                /// create mutable value since we will be using `.extract` which advances the buffer's view
                var value = value

                /// grab the numeric metadata from the beginning of the array
                let metadata = value.extract(PostgreSQLNumericMetadata.self)

                var integer = ""
                var fractional = ""
                for offset in 0..<metadata.ndigits.bigEndian {
                    /// extract current char and advance memory
                    let char = value.extract(Int16.self).bigEndian

                    /// conver the current char to its string form
                    let string: String
                    if char == 0 {
                        /// 0 means 4 zeros
                        string = "0000"
                    } else {
                        string = char.description
                    }

                    /// depending on our offset, append the string to before or after the decimal point
                    if offset < metadata.weight.bigEndian + 1 {
                        integer += string
                    } else {
                        fractional += string
                    }
                }

                /// use the dscale to remove extraneous zeroes at the end of the fractional part
                let lastSignificantIndex = fractional.index(fractional.startIndex, offsetBy: Int(metadata.dscale.bigEndian))
                fractional = String(fractional[..<lastSignificantIndex])

                /// determine whether fraction is empty and dynamically add `.`
                let numeric: String
                if fractional != "" {
                    numeric = integer + "." + fractional
                } else {
                    numeric = integer
                }

                /// use sign to determine adding a leading `-`
                if metadata.sign.bigEndian == 1 {
                    return "-" + numeric
                } else {
                    return numeric
                }
            default: throw PostgreSQLError(identifier: "string", reason: "Could not decode String from binary data type: \(data.type)")
            }
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return PostgreSQLData(type: .text, format: .binary, data: Data(utf8))
    }
}

/// Represents the meta information preceeding a numeric value.
/// Note: all values must be accessed adding `.bigEndian`
struct PostgreSQLNumericMetadata {
    /// The number of digits after this metadata
    var ndigits: Int16
    /// How many of the digits are before the decimal point (always add 1)
    var weight: Int16
    /// If 1, this number is negative. Otherwise, positive.
    var sign: Int16
    /// The number of sig digits after the decimal place (get rid of trailing 0s)
    var dscale: Int16
}

extension Data {
    /// Convert the row's data into a string, throwing if invalid encoding.
    internal func makeString(encoding: String.Encoding = .utf8) throws -> String {
        guard let string = String(data: self, encoding: encoding) else {
            throw PostgreSQLError(identifier: "utf8String", reason: "Unexpected non-UTF8 string: \(hexDebug).")
        }

        return string
    }
}
