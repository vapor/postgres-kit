import Foundation

/// A 2-dimenstional (double[2]) point.
public struct PostgreSQLPoint: Codable {
    /// The point's x coordinate.
    public var x: Double

    /// The point's y coordinate.
    public var y: Double

    /// Create a new `Point`
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

extension PostgreSQLPoint: CustomStringConvertible {
    /// See `CustomStringConvertible.description`
    public var description: String {
        return "(\(x),\(y))"
    }
}

extension PostgreSQLPoint: Equatable {
    /// See `Equatable.==`
    public static func ==(lhs: PostgreSQLPoint, rhs: PostgreSQLPoint) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

extension PostgreSQLPoint: PostgreSQLDataConvertible {
    /// See `PostgreSQLDataConvertible`.
    public static var postgreSQLDataType: PostgreSQLDataType { return .point }

    /// See `PostgreSQLDataConvertible`.
    public static var postgreSQLDataArrayType: PostgreSQLDataType { return ._point }

    /// See `PostgreSQLDataConvertible`.
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> PostgreSQLPoint {
        guard case .point = data.type else {
            throw PostgreSQLError(identifier: "point", reason: "Could not decode Point from data type: \(data.type)")
        }
        switch data.storage {
        case .text(let string):
            let parts = string.split(separator: ",")
            var x = parts[0]
            var y = parts[1]
            let leftParen = x.popFirst()
            assert(leftParen == "(")
            let rightParen = y.popLast()
            assert(rightParen == ")")
            return .init(x: Double(x)!, y: Double(y)!)
        case .binary(let value):
            let x = value[0..<8]
            let y = value[8..<16]
            return .init(x: x.makeFloatingPoint(), y: y.makeFloatingPoint())
        case .null: throw PostgreSQLError(identifier: "data", reason: "Could not decode Point from null data.")
        }
    }

    /// See `PostgreSQLDataConvertible`.
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return PostgreSQLData(.point, binary: x.data + y.data)
    }
}
