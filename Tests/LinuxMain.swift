import XCTest

import PostgreSQLTests

var tests = [XCTestCaseEntry]()
tests += PostgreSQLTests.__allTests()

XCTMain(tests)
