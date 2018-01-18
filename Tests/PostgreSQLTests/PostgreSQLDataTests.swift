import Foundation
import XCTest
import PostgreSQL

class PostgreSQLDataTests: XCTestCase {
    func testExample() throws {
        struct KitchenSink: Encodable {
            var int8: Int8
        }
        let test = KitchenSink(int8: 1)
        let data = try PostgreSQLDataEncoder().encode(test)
        XCTAssertEqual(data, .dictionary([
            "int8": .int8(1)
        ]))
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

