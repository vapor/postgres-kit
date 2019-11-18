import PostgresKit
import SQLKitBenchmark
import XCTest

class PostgresKitTests: XCTestCase {
    func testSQLKitBenchmark() throws {
        let conn = try PostgresConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        conn.logger.logLevel = .trace
        let benchmark = SQLBenchmarker(on: conn.sql())
        try benchmark.run()
    }
    
    func testPerformance() throws {
        let db = PostgresConnectionSource(
            configuration: .init(hostname: hostname, username: "vapor_username", password: "vapor_password", database: "vapor_database")
        )
        let pool = EventLoopGroupConnectionPool(
            source: db,
            maxConnectionsPerEventLoop: 2,
            on: self.eventLoopGroup
        )
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
        let db = conn.sql()

        try db.create(enum: "meal", cases: "breakfast", "lunch", "dinner").run().wait()
        try db.raw("DROP TYPE meal;").run().wait()

        try db.create(enum: SQLIdentifier("meal"), cases: "breakfast", "lunch", "dinner").run().wait()
        try db.raw("DROP TYPE meal;").run().wait()
    }

    func testDropEnumWithBuilder() throws {
        let conn = try PostgresConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let db = conn.sql()

        // these two should work even if the type does not exist
        try db.drop(type: "meal").ifExists().run().wait()
        try db.drop(type: "meal").ifExists().cascade().run().wait()

        try db.create(enum: "meal", cases: "breakfast", "lunch", "dinner").run().wait()
        try db.drop(type: "meal").ifExists().cascade().run().wait()

        try db.create(enum: "meal", cases: "breakfast", "lunch", "dinner").run().wait()
        try db.drop(type: "meal").run().wait()

        try db.create(enum: "meal", cases: "breakfast", "lunch", "dinner").run().wait()
        try db.drop(type: SQLIdentifier("meal")).run().wait()

        try db.create(enum: "meal", cases: "breakfast", "lunch", "dinner").run().wait()
        try db.drop(type: "meal").cascade().run().wait()
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
}
