import Foundation
import XCTest
@testable import PostgreSQL

class PostgreSQLMessageTests: XCTestCase {
    func testExample() throws {
        let startup = PostgreSQLStartupMessage.versionThree(parameters: ["user": "tanner"])
        let data = try PostgreSQLMessageEncoder().encode(.startupMessage(startup))
        XCTAssertEqual(data.hexDebug, "0x00 00 00 15 00 03 00 00 75 73 65 72 00 74 61 6E 6E 65 72 00 00")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
