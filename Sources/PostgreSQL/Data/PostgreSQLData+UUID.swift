import Foundation

extension UUID: PostgreSQLDataCustomConvertible {
    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> UUID {
        guard let value = data.data else {
            throw PostgreSQLError(identifier: "data", reason: "Could not decode UUID from `null` data.")
        }
        switch data.type {
        case .uuid:
            switch data.format {
            case .text:
                let string = try value.makeString()
                guard let uuid = UUID(uuidString: string) else {
                    throw PostgreSQLError(identifier: "uuid", reason: "Could not decode UUID from string: \(string)")
                }
                return uuid
            case .binary: return UUID(uuid: value.unsafeCast())
            }
        default: throw PostgreSQLError(identifier: "uuid", reason: "Could not decode UUID from data type: \(data.type)")
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        var uuid = self.uuid
        return PostgreSQLData(type: .uuid, format: .binary, data: withUnsafePointer(to: &uuid) {
            Data(bytes: $0, count: MemoryLayout.size(ofValue: uuid))
        })
    }
}
