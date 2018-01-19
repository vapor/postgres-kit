import XCTest
@testable import PostgreSQLTests

XCTMain([
    testCase(PostgreSQLConnectionTests.allTests),
    testCase(PostgreSQLMessageTests.allTests),
])
