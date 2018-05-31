import Foundation

extension UUID: PostgreSQLDataConvertible {
    /// See `PostgreSQLDataConvertible`.
    public static var postgreSQLDataType: PostgreSQLDataType { return .uuid }


    /// See `PostgreSQLDataConvertible`.
    public static var postgreSQLDataArrayType: PostgreSQLDataType { return ._uuid }

    /// See `PostgreSQLDataConvertible`.
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> UUID {
        guard case .uuid = data.type else {
            throw PostgreSQLError(identifier: "uuid", reason: "Could not decode UUID from data type: \(data.type)")
        }
        switch data.storage {
        case .text(let string):
            guard let uuid = UUID(uuidString: string) else {
                throw PostgreSQLError(identifier: "uuid", reason: "Could not decode UUID from string: \(string)")
            }
            return uuid
        case .binary(let value): return UUID(uuid: value.unsafeCast())
        case .null: throw PostgreSQLError(identifier: "uuid", reason: "Could not decode UUID from null data.")
        }
    }

    /// See `PostgreSQLDataConvertible`.
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        var uuid = self.uuid
        let size = MemoryLayout.size(ofValue: uuid)
        return PostgreSQLData(.uuid, binary: withUnsafePointer(to: &uuid) {
            Data(bytes: $0, count: size)
        })
    }
}
