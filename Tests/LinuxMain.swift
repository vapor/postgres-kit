import XCTest
@testable import PostgreSQLTests

XCTMain([
    testCase(ConnectionTests.allTests),
    testCase(PerformanceTests.allTests),
])
