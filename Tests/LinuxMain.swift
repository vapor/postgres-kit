import XCTest
@testable import PostgreSQLTests

XCTMain([
    testCase(PostgreSQLClientTests.allTests),
    testCase(PostgreSQLMessageTests.allTests),
])
