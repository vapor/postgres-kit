import PostgresKit
import SQLKitBenchmark
import XCTest

class PostgresKitTests: XCTestCase {
    private var eventLoopGroup: EventLoopGroup!
    private var eventLoop: EventLoop {
        return self.eventLoopGroup.next()
    }
    
    override func setUp() {
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }
    
    override func tearDown() {
        XCTAssertNoThrow(try self.eventLoopGroup.syncShutdownGracefully())
        self.eventLoopGroup = nil
    }
    
    
    func testSQLKitBenchmark() throws {
        let conn = try PostgresConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let benchmark = SQLBenchmarker(on: conn)
        try benchmark.run()
    }
    
    func testPerformance() throws {
        let db = PostgresConnectionSource(
            configuration: .init(hostname: hostname, username: "vapor_username", password: "vapor_password", database: "vapor_database")
        )
        let pool = ConnectionPool(configuration: .init(maxConnections: 12), source: db, on: self.eventLoopGroup)
        defer { pool.shutdown() }
        self.measure {
            for _ in 1...100 {
                _ = try! pool.withConnection { conn in
                    return conn.query("SELECT 1;")
                }.wait()
            }
        }
    }

    func testCreateEnumWithBuilder() throws {
        let conn = try PostgresConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }

        try conn.create(enum: "meal", cases: "breakfast", "lunch", "dinner").run().wait()
        try conn.raw("DROP TYPE meal;").run().wait()

        try conn.create(enum: SQLIdentifier("meal"), cases: "breakfast", "lunch", "dinner").run().wait()
        try conn.raw("DROP TYPE meal;").run().wait()
    }

    func testDropEnumWithBuilder() throws {
        let conn = try PostgresConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }

        // these two should work even if the type does not exist
        try conn.drop(type: "meal").ifExists().run().wait()
        try conn.drop(type: "meal").ifExists().cascade().run().wait()

        try conn.create(enum: "meal", cases: "breakfast", "lunch", "dinner").run().wait()
        try conn.drop(type: "meal").ifExists().cascade().run().wait()

        try conn.create(enum: "meal", cases: "breakfast", "lunch", "dinner").run().wait()
        try conn.drop(type: "meal").run().wait()

        try conn.create(enum: "meal", cases: "breakfast", "lunch", "dinner").run().wait()
        try conn.drop(type: SQLIdentifier("meal")).run().wait()

        try conn.create(enum: "meal", cases: "breakfast", "lunch", "dinner").run().wait()
        try conn.drop(type: "meal").cascade().run().wait()
    }

    func testLeak() throws {
        struct Foo: Codable {
            var id: String
            var description: String?
            var latitude: Double
            var longitude: Double
            var created_by: String
            var created_at: Date
            var modified_by: String
            var modified_at: Date
        }
        
        let conn = try PostgresConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        
        try conn.raw("DROP TABLE IF EXISTS foos").run().wait()
        try conn.raw("""
        CREATE TABLE foos (
            id TEXT PRIMARY KEY,
            description TEXT,
            latitude DOUBLE PRECISION,
            longitude DOUBLE PRECISION,
            created_by TEXT,
            created_at TIMESTAMPTZ,
            modified_by TEXT,
            modified_at TIMESTAMPTZ
        )
        """).run().wait()
        defer {
            try? conn.raw("DROP TABLE IF EXISTS foos").run().wait()
        }
        
        for i in 0..<5_000 {
            let zipcode = Foo(
                id: UUID().uuidString,
                description: "test \(i)",
                latitude: Double.random(in: 0...100),
                longitude: Double.random(in: 0...100),
                created_by: "test",
                created_at: Date(),
                modified_by: "test",
                modified_at: Date()
            )
            try conn.insert(into: "foos")
                .model(zipcode)
                .run().wait()
        }
    }
}
