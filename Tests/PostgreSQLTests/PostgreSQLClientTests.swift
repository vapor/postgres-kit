import Async
import Foundation
import XCTest
@testable import PostgreSQL
import TCP

class PostgreSQLClientTests: XCTestCase {
    func testVersion() throws {
        let (client, eventLoop) = try PostgreSQLClient.makeTest()
        let results = try client.query("SELECT version();").await(on: eventLoop)
        XCTAssert(results[0]["version"]?.string?.contains("10.1") == true)
    }

    func testSelectTypes() throws {
        let (client, eventLoop) = try PostgreSQLClient.makeTest()
        let results = try client.query("select * from pg_type;").await(on: eventLoop)
        XCTAssert(results.count > 350)
    }

    func testParse() throws {
        let (client, eventLoop) = try! PostgreSQLClient.makeTest()
        let query = """
        select * from "pg_type" where "typlen" = $1 or "typlen" = $2
        """
        try client.parameterizedQuery(query, [
            .int32(1),
            .int32(2),
        ]).await(on: eventLoop)
    }

    static var allTests = [
        ("testVersion", testVersion),
    ]
}

extension PostgreSQLClient {
    /// Creates a test event loop and psql client.
    static func makeTest() throws -> (PostgreSQLClient, EventLoop) {
        let eventLoop = try DefaultEventLoop(label: "codes.vapor.postgresql.client.test")
        let client = try PostgreSQLClient.connect(on: eventLoop)

        let startup = PostgreSQLStartupMessage.versionThree(parameters: ["user": "postgres"])
        _ = try client.send(.startupMessage(startup)).await(on: eventLoop)
        return (client, eventLoop)
    }
}
