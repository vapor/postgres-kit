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

    func testPostgresConfigurationURLValidation() throws {
        
        /// PostgresConfiguration must have user, but should be...?
        XCTAssertNil(PostgresConfiguration(url: "postgres://localhost"))
        XCTAssertNil(PostgresConfiguration(url: "postgres://localhost:5433"))
        XCTAssertNil(PostgresConfiguration(url: "postgres://localhost/mydb"))
        
        /// ... but PostgresConfiguration with empty user pass the test
        XCTAssertNotNil(PostgresConfiguration(url: "postgres://@localhost"))
        
        XCTAssertNotNil(PostgresConfiguration(url: "postgres://user@127.0.0.1"))
        XCTAssertNotNil(PostgresConfiguration(url: "postgres://user@localhost:5432"))
        XCTAssertNotNil(PostgresConfiguration(url: "postgres://user@127.0.0.1:5430"))
        XCTAssertNotNil(PostgresConfiguration(url: "postgres://user:secret@localhost"))
        XCTAssertNotNil(PostgresConfiguration(url: "postgres://user:pass%word@127.0.0.1:5432"))
        XCTAssertNotNil(PostgresConfiguration(url: "postgres://user:pa%ss%wor%d@127.0.0.1:5432/db"))
        XCTAssertNotNil(PostgresConfiguration(url: "postgres://other@localhost/somedb?connect_timeout=10&application_name=myapp"))
    }
    
    func testPostgresConfigurationURLComponents() throws {
        
        let basicConfiguration: PostgresConfiguration = PostgresConfiguration(url: "postgres://user:password@localhost/db")!
        XCTAssertEqual(basicConfiguration.username, "user")
        XCTAssertEqual(basicConfiguration.password, "password")
        XCTAssertEqual(basicConfiguration.database, "db")
        
        let encodedPasswordConfiguration: PostgresConfiguration = PostgresConfiguration(url: "postgres://user:2kf%D@127.0.0.1:5432/db1")!
        XCTAssertEqual(encodedPasswordConfiguration.username, "user")
        XCTAssertEqual(encodedPasswordConfiguration.password, "2kf%D")
        XCTAssertNotEqual(encodedPasswordConfiguration.password, "2kf%25D")
        XCTAssertEqual(encodedPasswordConfiguration.database, "db1")
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
    
    /// Tests dealing with encoding of values whose `encode(to:)` implementation calls one of the `superEncoder()`
    /// methods (most notably the implementation of `Codable` for Fluent's `Fields`, which we can't directly test
    /// at this layer).
    func testValuesThatUseSuperEncoder() throws {
        struct UnusualType: Codable {
            var prop1: String, prop2: [Bool], prop3: [[Bool]]
            
            // This is intentionally contrived - Fluent's implementation does Codable this roundabout way as a
            // workaround for the interaction of property wrappers with optional properties; it serves no purpose
            // here other than to demonstrate that the encoder supports it.
            private enum CodingKeys: String, CodingKey { case prop1, prop2, prop3 }
            init(prop1: String, prop2: [Bool], prop3: [[Bool]]) { (self.prop1, self.prop2, self.prop3) = (prop1, prop2, prop3) }
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.prop1 = try .init(from: container.superDecoder(forKey: .prop1))
                var acontainer = try container.nestedUnkeyedContainer(forKey: .prop2), ongoing: [Bool] = []
                while !acontainer.isAtEnd { ongoing.append(try Bool.init(from: acontainer.superDecoder())) }
                self.prop2 = ongoing
                var bcontainer = try container.nestedUnkeyedContainer(forKey: .prop3), bongoing: [[Bool]] = []
                while !bcontainer.isAtEnd {
                    var ccontainer = try bcontainer.nestedUnkeyedContainer(), congoing: [Bool] = []
                    while !ccontainer.isAtEnd { congoing.append(try Bool.init(from: ccontainer.superDecoder())) }
                    bongoing.append(congoing)
                }
                self.prop3 = bongoing
            }
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try self.prop1.encode(to: container.superEncoder(forKey: .prop1))
                var acontainer = container.nestedUnkeyedContainer(forKey: .prop2)
                for val in self.prop2 { try val.encode(to: acontainer.superEncoder()) }
                var bcontainer = container.nestedUnkeyedContainer(forKey: .prop3)
                for arr in self.prop3 {
                    var ccontainer = bcontainer.nestedUnkeyedContainer()
                    for val in arr { try val.encode(to: ccontainer.superEncoder()) }
                }
            }
        }
        
        let instance = UnusualType(prop1: "hello", prop2: [true, false, false, true], prop3: [[true, true], [false], [true], []])
        let encoded1 = try PostgresDataEncoder().encode(instance)
        let encoded2 = try PostgresDataEncoder().encode([instance, instance])
        
        XCTAssertEqual(encoded1.type, .jsonb)
        XCTAssertEqual(encoded2.type, .jsonbArray)
        
        let decoded1 = try PostgresDataDecoder().decode(UnusualType.self, from: encoded1)
        let decoded2 = try PostgresDataDecoder().decode([UnusualType].self, from: encoded2)
        
        XCTAssertEqual(decoded1.prop3, instance.prop3)
        XCTAssertEqual(decoded2.count, 2)
    }

    var eventLoop: EventLoop { self.eventLoopGroup.any() }
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
