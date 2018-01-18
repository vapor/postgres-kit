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

    static var allTests = [
        ("testEncode", testEncode),
        ("testDecode", testDecode),
    ]
}

struct KitchenSink: Codable, Equatable {
    static func ==(lhs: KitchenSink, rhs: KitchenSink) -> Bool {
        return lhs.int8 == rhs.int8
    }

    var int8: Int8
    static let test = KitchenSink(int8: 1)
}

extension PostgreSQLData {
    static let kitchenSink = PostgreSQLData.dictionary([
        "int8": .int8(1)
    ])
}
