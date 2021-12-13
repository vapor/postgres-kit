import PostgresKit
import SQLKitBenchmark
import XCTest
import Logging

class PostgresKitTests: XCTestCase {
    func testSQLKitBenchmark() throws {
        let conn = try PostgresConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let benchmark = SQLBenchmarker(on: conn.sql())
        try benchmark.run()
    }
    
    func testPerformance() throws {
        let db = PostgresConnectionSource(configuration: .test)
        let pool = EventLoopGroupConnectionPool(
            source: db,
            maxConnectionsPerEventLoop: 2,
            on: self.eventLoopGroup
        )
        defer { pool.shutdown() }
        // Postgres seems to take much longer on initial connections when using SCRAM-SHA-256 auth,
        // which causes XCTest to bail due to the first measurement having a very high deviation.
        // Spin the pool a bit before running the measurement to warm it up.
        for _ in 1...25 {
            _ = try pool.withConnection { conn in
                return conn.query("SELECT 1;")
            }.wait()
        }
        self.measure {
            for _ in 1...100 {
                _ = try! pool.withConnection { conn in
                    return conn.query("SELECT 1;")
                }.wait()
            }
        }
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
        
        let db = conn.sql()
        
        try db.raw("DROP TABLE IF EXISTS foos").run().wait()
        try db.raw("""
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
            try? db.raw("DROP TABLE IF EXISTS foos").run().wait()
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
            try db.insert(into: "foos")
                .model(zipcode)
                .run().wait()
        }
    }

    func testArrayEncoding() throws {
        let conn = try PostgresConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        
        struct Foo: Codable {
            var bar: Int
        }
        let foos: [Foo] = [.init(bar: 1), .init(bar: 2)]
        try conn.sql().raw("SELECT \(bind: foos)::JSONB[] as foos")
            .run().wait()
    }

    func testDictionaryEncoding() throws {
        let conn = try PostgresConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }

        struct Foo: Codable {
            var bar: Int
        }
    }

    func testDecodeModelWithNil() throws {
        let conn = try PostgresConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }

        let rows = try conn.query("SELECT 'foo'::text as foo, null as bar, 'baz'::text as baz").wait()
        let row = rows[0]
        
        struct Test: Codable {
            var foo: String
            var bar: String?
            var baz: String?
        }

        let test = try row.sql().decode(model: Test.self)
        XCTAssertEqual(test.foo, "foo")
        XCTAssertEqual(test.bar, nil)
        XCTAssertEqual(test.baz, "baz")
    }

    func testEventLoopGroupSQL() throws {
        var configuration = PostgresConfiguration.test
        configuration.searchPath = ["foo", "bar", "baz"]
        let source = PostgresConnectionSource(configuration: configuration)
        let pool = EventLoopGroupConnectionPool(source: source, on: self.eventLoopGroup)
        defer { pool.shutdown() }
        let db = pool.database(logger: .init(label: "test")).sql()

        let rows = try db.raw("SELECT version();").all().wait()
        print(rows)
    }

    func testArrayEncoding_json() throws {
        let connection = try PostgresConnection.test(on: self.eventLoop).wait()
        defer { try! connection.close().wait() }
        _ = try connection.query("DROP TABLE IF EXISTS foo").wait()
        _ = try connection.query("CREATE TABLE foo (bar integer[] not null)").wait()
        defer {
            _ = try! connection.query("DROP TABLE foo").wait()
        }
        _ = try connection.query("INSERT INTO foo (bar) VALUES ($1)", [
            PostgresDataEncoder().encode([Bar]())
        ]).wait()
        let rows = try connection.query("SELECT * FROM foo").wait()
        print(rows)
    }
      
    func testEnum() throws {
        let connection = try PostgresConnection.test(on: self.eventLoop).wait()
        defer { try! connection.close().wait() }
        try SQLBenchmarker(on: connection.sql()).testEnum()
    }

    var eventLoop: EventLoop { self.eventLoopGroup.next() }
    var eventLoopGroup: EventLoopGroup!

    override func setUpWithError() throws {
        try super.setUpWithError()
        XCTAssertTrue(isLoggingConfigured)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    }

    override func tearDownWithError() throws {
        try self.eventLoopGroup.syncShutdownGracefully()
        self.eventLoopGroup = nil
        try super.tearDownWithError()
    }
}

enum Bar: Int, Codable {
    case one, two
}

extension Bar: PostgresDataConvertible { }

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = env("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ?? .debug
        return handler
    }
    return true
}()
