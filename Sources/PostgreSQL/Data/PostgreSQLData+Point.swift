import Foundation

/// A 2-dimenstional (double[2]) point.
public struct PostgreSQLPoint {
    /// The point's x coordinate.
    var x: Double

    /// The point's y coordinate.
    var y: Double

    /// Create a new `Point`
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

extension PostgreSQLPoint: PostgreSQLDataCustomConvertible {
    /// See `PostgreSQLDataCustomConvertible.preferredDataType`
    public static var preferredDataType: PostgreSQLDataType? { return .point }

    /// See `PostgreSQLDataCustomConvertible.convertFromPostgreSQLData(_:)`
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> PostgreSQLPoint {
        guard let value = data.data else {
            throw PostgreSQLError(identifier: "data", reason: "Could not decode Point from `null` data.")
        }
        switch data.type {
        case .point:
            switch data.format {
            case .text:
                let string = try value.makeString()
                let parts = string.split(separator: ",")
                var x = parts[0]
                var y = parts[1]
                assert(x.popFirst()! == "(")
                assert(y.popLast()! == ")")
                return .init(x: Double(x)!, y: Double(y)!)
            case .binary:
                let x = value[0..<8]
                let y = value[8..<16]
                return .init(x: x.makeFloatingPoint(), y: y.makeFloatingPoint())
            }
        default: throw PostgreSQLError(identifier: "point", reason: "Could not decode Point from data type: \(data.type)")
        }
    }

    /// See `PostgreSQLDataCustomConvertible.convertToPostgreSQLData()`
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return PostgreSQLData(type: .point, format: .binary, data: x.data + y.data)
    }
}
