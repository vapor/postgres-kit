@testable import PostgreSQL
import SQLBenchmark
import XCTest

class PerformanceTests: XCTestCase {
    func testRangeSelectDecodePerformance() throws {
        struct Series: Decodable {
            var num: Int
        }
        
        let conn = try PostgreSQLConnection.makeTest()
        measure {
            do {
                try conn.simpleQuery("SELECT * FROM generate_series(1, 10000) num") { row in
                    _ = try conn.decode(Series.self, from: row, table: nil)
                }.wait()
            } catch {
                XCTFail("\(error)")
            }
        }
    }
}
