import Foundation

extension Data: PostgreSQLDataCustomConvertible {
    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Data {
        guard let value = data.data else {
            throw PostgreSQLError(identifier: "data", reason: "Could not decode Data from `null` data.")
        }

        switch data.type {
        case .bytea:
            switch data.format {
            case .text: return try Data(hexString: value[2...].makeString())
            case .binary: return value
            }
        default: throw PostgreSQLError(identifier: "data", reason: "Could not decode Data from data type: \(data.type)")
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return PostgreSQLData(type: .bytea, format: .binary, data: self)
    }
}

extension Data {
    /// Initialize data from a hex string.
    internal init(hexString: String) {
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
