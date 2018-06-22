import PostgreSQL
import XCTest

class PostgreSQLUpsertTests: XCTestCase {

    func testUpsert() throws {
        let values: [(PostgreSQLUpsert.Identifier, PostgreSQLUpsert.Expression)] = []

        var upsert: PostgreSQLUpsert

        upsert = PostgreSQLUpsert.upsert(nil, values)
        XCTAssertEqual(upsert.columns, [PostgreSQLColumnIdentifier.column(nil, .identifier("id"))])

        upsert = PostgreSQLUpsert.upsert([], values)
        XCTAssertEqual(upsert.columns, [PostgreSQLColumnIdentifier.column(nil, .identifier("id"))])

        upsert = PostgreSQLUpsert.upsert([.column(nil, .identifier("field"))], values)
        XCTAssertEqual(upsert.columns, [PostgreSQLColumnIdentifier.column(nil, .identifier("field"))])
    }

    static var allTests = [
        ("testUpsert", testUpsert),
    ]
}
