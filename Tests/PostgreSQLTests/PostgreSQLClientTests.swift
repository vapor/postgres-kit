import Async
import Foundation
import XCTest
@testable import PostgreSQL
import TCP

class PostgreSQLClientTests: XCTestCase {
    func testStreaming() throws {
        let eventLoop = try DefaultEventLoop(label: "codes.vapor.postgresql.client.test")
        let client = try PostgreSQLClient.connect(on: eventLoop)

        let startup = PostgreSQLStartupMessage.versionThree(parameters: ["user": "postgres"])
        let startupRes = try client.send(.startupMessage(startup)).await(on: eventLoop)
        for log in startupRes {
            switch log {
            case .parameterStatus(let param):
                if param.parameter == "session_authorization" {
                    XCTAssertEqual(param.value, "postgres")
                }
            default: break
            }
        }

        let results = try client.query("SELECT version();").await(on: eventLoop)
        print(results[0]["version"]!)
    }

    static var allTests = [
        ("testStreaming", testStreaming),
    ]
}
