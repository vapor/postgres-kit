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
        return PostgreSQLData(type: dataType, format: format, data: value)
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
