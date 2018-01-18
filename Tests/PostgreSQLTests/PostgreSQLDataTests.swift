import Foundation
import XCTest
import PostgreSQL

class PostgreSQLDataTests: XCTestCase {
    func testEncode() throws {
        let data = try PostgreSQLDataEncoder().encode(KitchenSink.test)
        XCTAssertEqual(data, .kitchenSink)
    }

    func testDecode() throws {
        let kitchenSink = try PostgreSQLDataDecoder().decode(KitchenSink.self, from: .kitchenSink)
        XCTAssertEqual(kitchenSink, .test)
    }

    func testCodable() throws {
        let original = KitchenSink.test
        let encoded = try PostgreSQLDataEncoder().encode(KitchenSink.test)
        let decoded = try PostgreSQLDataDecoder().decode(KitchenSink.self, from: encoded)
        XCTAssertEqual(decoded, original)
    }

    static var allTests = [
        ("testEncode", testEncode),
        ("testDecode", testDecode),
        ("testCodable", testCodable),
    ]
}

struct KitchenSink: Codable, Equatable {
    static func ==(lhs: KitchenSink, rhs: KitchenSink) -> Bool {
        return
            lhs.int8 == rhs.int8 &&
            lhs.int16 == rhs.int16 &&
            lhs.int32 == rhs.int32 &&
            lhs.int64 == rhs.int64 &&
            lhs.uint8 == rhs.uint8 &&
            lhs.uint16 == rhs.uint16 &&
            lhs.uint32 == rhs.uint32 &&
            lhs.uint64 == rhs.uint64 &&
            lhs.float == rhs.float &&
            lhs.double == rhs.double &&
            lhs.array == rhs.array
    }

    static let test = KitchenSink(
        int8: 1, int16: 2, int32: 3, int64: 4, uint8: 5, uint16: 6, uint32: 7, uint64: 8, float: 9.1, double: 10.2, array: [1, 2, 3]
    )
    
    var int8: Int8
    var int16: Int16
    var int32: Int32
    var int64: Int64
    var uint8: UInt8
    var uint16: UInt16
    var uint32: UInt32
    var uint64: UInt64
    var float: Float
    var double: Double
    var array: [Int]
}

extension PostgreSQLData {
    static let kitchenSink = PostgreSQLData.dictionary([
        "int8": .int8(1),
        "int16": .int16(2),
        "int32": .int32(3),
        "int64": .int64(4),
        "uint8": .int8(5),
        "uint16": .int16(6),
        "uint32": .int32(7),
        "uint64": .int64(8),
        "float": .float(9.1),
        "double": .double(10.2),
        "array": .array([.int64(1), .int64(2), .int64(3)])
    ])
}
