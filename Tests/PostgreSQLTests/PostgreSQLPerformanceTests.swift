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
            let decoder = PostgreSQLRowDecoder()
            do {
                try conn.simpleQuery("SELECT * FROM generate_series(1, 10000) num") { row in
                    _ = try decoder.decode(Series.self, from: row)
                }.wait()
            } catch {
                XCTFail("\(error)")
            }
        }
    }

    static var allTests = [
        ("testRangeSelectDecodePerformance", testRangeSelectDecodePerformance),
    ]
}
