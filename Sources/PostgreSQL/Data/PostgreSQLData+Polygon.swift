import Foundation

/// A 2-dimensional list of (double[2]) points representing a polygon.
public struct PostgreSQLPolygon: Codable, Equatable {
    /// The points that make up the polygon.
    public var points: [PostgreSQLPoint]

    /// Create a new `Point`
    public init(points: [PostgreSQLPoint]) {
        self.points = points
    }
}

extension PostgreSQLPolygon: CustomStringConvertible {
    /// See `CustomStringConvertible`.
    public var description: String {
        return "(\(self.points.map{ $0.description }.joined(separator: ",")))"
    }
}

extension PostgreSQLPolygon: PostgreSQLDataConvertible {

    /// See `PostgreSQLDataConvertible`.
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> PostgreSQLPolygon {
        guard case .polygon = data.type else {
            throw PostgreSQLError.decode(self, from: data)
        }
        switch data.storage {
        case .text(let string):
            var points = [PostgreSQLPoint]()
            var count = 0
            
            let parts = string.split(separator: ",")
            while count < parts.count {
                var x = parts[count]
                var y = parts[count+1]
                
                // Check initial "("
                if count == 0 { assert(x.popFirst() == "(") }
                
                count += 2
                
                // Check end ")"
                if count == parts.count { assert(y.popLast() == ")") }
                
                // Check Normal "(" and ")"
                assert(x.popFirst() == "(")
                assert(y.popLast() == ")")
                
                // Create the point
                points.append(PostgreSQLPoint(x: Double(x)!, y: Double(y)!))
            }
            return .init(points: points)
        case .binary(let value):
            let total = value[0..<4].as(UInt32.self, default: 0).bigEndian
            assert(total == (value.count-4)/16)
            
            var points = [PostgreSQLPoint]()
            var count = 4
            while count < value.count {
                let x = Data(bytes: value[count..<count+8].reversed()).as(Double.self, default: 0)
                let y = Data(bytes: value[count+8..<count+16].reversed()).as(Double.self, default: 0)
                points.append(PostgreSQLPoint(x: x, y: y))
                count += 16
            }
            
            return .init(points: points)
            
        case .null: throw PostgreSQLError.decode(self, from: data)
        }
    }
    
    /// See `PostgreSQLDataConvertible`.
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        var binary = Data.of(Int32(self.points.count).bigEndian)
        for point in self.points {
            binary += Data(bytes: Data.of(point.x).reversed())
            binary += Data(bytes: Data.of(point.y).reversed())
        }
        return PostgreSQLData(.polygon, binary: binary)
    }
}
