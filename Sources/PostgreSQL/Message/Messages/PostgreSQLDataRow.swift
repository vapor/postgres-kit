import Bits
import Foundation

/// Identifies the message as a data row.
struct PostgreSQLDataRow: Decodable {
    /// The data row's columns
    var columns: [PostgreSQLDataRowColumn]

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

    init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        /// The length of the column value, in bytes (this count does not include itself).
        /// Can be zero. As a special case, -1 indicates a NULL column value. No value bytes follow in the NULL case.
        let count = try single.decode(Int32.self)
        switch count {
        case -1: value = nil
        case 0: value = .init()
        case 1...:
            // FIXME: optimize
            var bytes: [Byte] = []
            for _ in 0..<count {
                let byte = try single.decode(Byte.self)
                bytes.append(byte)
            }
            value = Data(bytes)
        default: fatalError("Illegal data row column value count: \(count)")
        }
    }
}
