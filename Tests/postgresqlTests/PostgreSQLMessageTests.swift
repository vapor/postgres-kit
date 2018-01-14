import Foundation
import XCTest
@testable import PostgreSQL

class PostgreSQLMessageTests: XCTestCase {
    func testExample() throws {
        let startup = PostgreSQLStartupMessage.versionThree(parameters: ["user": "tanner"])
        let data = try PostgreSQLMessageEncoder().encode(startup)
        XCTAssertEqual(data.hexDebug, "[0x0, 0x0, 0x0, 0x11, 0x0, 0x3, 0x0, 0x0, 0x75, 0x73, 0x65, 0x72, 0x0, 0x74, 0x61, 0x6E, 0x6E, 0x65, 0x72, 0x0, 0x0]")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

extension Data {
    public var hexDebug: String {
        var hex: [String] = []
        for byte in self {
            hex.append("0x" + String(byte, radix: 16, uppercase: true))
        }
        return "[" + hex.joined(separator: ", ") + "]"
    }
}
