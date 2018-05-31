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
    func parse(dataType: PostgreSQLDataType, format: PostgreSQLMessage.FormatCode) throws -> PostgreSQLData {
        guard let value = value else {
            return PostgreSQLData(null: dataType)
        }
        
        switch format {
        case .binary: return PostgreSQLData(dataType, binary: value)
        case .text:
            guard let string = String(data: value, encoding: .utf8) else {
                throw PostgreSQLError(identifier: "utf8", reason: "Invalid UTF8 string: \(value)")
            }
            return PostgreSQLData(dataType, text: string)
        }
    }
}

extension PostgreSQLDataRowColumn: CustomStringConvertible {
    var description: String {
        if let value = value {
            return String(data: value, encoding: .ascii) ?? value.hexDebug
        } else {
            return "<null>"
        }
    }
}
