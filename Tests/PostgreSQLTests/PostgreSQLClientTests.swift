import Async
import Foundation
import XCTest
@testable import PostgreSQL
import TCP

class PostgreSQLClientTests: XCTestCase {
    func testExample() throws {
        let eventLoop = try DefaultEventLoop(label: "codes.vapor.postgresql.client.test")
        let client = try PostgreSQLClient.connect(on: eventLoop)
        let startup = PostgreSQLStartupMessage.versionThree(parameters: ["user": "postgres"])
        let res = try client.send(.startupMessage(startup)).await(on: eventLoop)
        print(res)
    }

    func testStreaming() throws {
        let eventLoop = try DefaultEventLoop(label: "codes.vapor.postgresql.client.test")
        let client = try PostgreSQLClient.connect(on: eventLoop)

        let startup = PostgreSQLStartupMessage.versionThree(parameters: ["user": "postgres"])
        let startupRes = try client.send(.startupMessage(startup)).await(on: eventLoop)
        print(startupRes)

        let query = PostgreSQLQuery(query: "SELECT version();")
        let queryOutput = try client.send(.query(query)).await(on: eventLoop)
        print(queryOutput)
    }

    static var allTests = [
        ("testExample", testExample),
        ("testStreaming", testStreaming),
    ]
}
