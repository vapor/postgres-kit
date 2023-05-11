@testable import PostgresKit
import SQLKitBenchmark
import XCTest
import Logging
import PostgresNIO
import NIOCore
import Foundation

final class PostgresKitTests: XCTestCase {
    func testSQLKitBenchmark() throws {
        let conn = try PostgresConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let benchmark = SQLBenchmarker(on: conn.sql())
        try benchmark.run()
    }
    
    func testPerformance() throws {
        let db = PostgresConnectionSource(sqlConfiguration: .test)
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
                conn.query("SELECT 1;")
            }.wait()
        }
        self.measure {
            for _ in 1...100 {
                _ = try! pool.withConnection { conn in
                    conn.query("SELECT 1;")
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
        
        try db.raw("DROP TABLE IF EXISTS \(ident: "foos")").run().wait()
        try db.raw("""
        CREATE TABLE \(ident: "foos") (
            \(ident: "id") TEXT PRIMARY KEY,
            \(ident: "description") TEXT,
            \(ident: "latitude") DOUBLE PRECISION,
            \(ident: "longitude") DOUBLE PRECISION,
            \(ident: "created_by") TEXT,
            \(ident: "created_at") TIMESTAMPTZ,
            \(ident: "modified_by") TEXT,
            \(ident: "modified_at") TIMESTAMPTZ
        )
        """).run().wait()
        defer {
            try? db.raw("DROP TABLE IF EXISTS \(ident: "foos")").run().wait()
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
        try conn.sql().raw("SELECT \(bind: foos)::JSONB[] as \(ident: "foos")")
            .run().wait()
    }

    func testDecodeModelWithNil() throws {
        let conn = try PostgresConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }

        let rows = try conn.sql().raw("SELECT \(literal: "foo")::text as \(ident: "foo"), \(SQLLiteral.null) as \(ident: "bar"), \(literal: "baz")::text as \(ident: "baz")").all().wait()
        let row = rows[0]
        
        struct Test: Codable {
            var foo: String
            var bar: String?
            var baz: String?
        }

        let test = try row.decode(model: Test.self)
        XCTAssertEqual(test.foo, "foo")
        XCTAssertEqual(test.bar, nil)
        XCTAssertEqual(test.baz, "baz")
    }

    func testEventLoopGroupSQL() throws {
        var configuration = SQLPostgresConfiguration.test
        configuration.searchPath = ["foo", "bar", "baz"]
        let source = PostgresConnectionSource(sqlConfiguration: configuration)
        let pool = EventLoopGroupConnectionPool(source: source, on: self.eventLoopGroup)
        defer { pool.shutdown() }
        let db = pool.database(logger: .init(label: "test")).sql()

        let rows = try db.raw("SELECT version();").all().wait()
        print(rows)
    }

    func testIntegerArrayEncoding() throws {
        let connection = try PostgresConnection.test(on: self.eventLoop).wait()
        defer { try! connection.close().wait() }
        let sql = connection.sql()
        _ = try sql.raw("DROP TABLE IF EXISTS \(ident: "foo")").run().wait()
        _ = try sql.raw("CREATE TABLE \(ident: "foo") (\(ident: "bar") bigint[] not null)").run().wait()
        defer {
            _ = try! sql.raw("DROP TABLE IF EXISTS \(ident: "foo")").run().wait()
        }
        _ = try sql.raw("INSERT INTO \(ident: "foo") (\(ident: "bar")) VALUES (\(bind: [Bar]()))").run().wait()
        let rows = try connection.query("SELECT bar FROM foo", logger: connection.logger).wait()
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.count, 1)
        XCTAssertEqual(rows.first?.first?.dataType, Bar.psqlArrayType)
        XCTAssertEqual(try rows.first?.first?.decode([Bar].self), [Bar]())
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
            init(from decoder: any Decoder) throws {
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
            func encode(to encoder: any Encoder) throws {
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
        let encoded1 = try PostgresDataTranslation.encode(codingPath: [], userInfo: [:], value: instance, in: .default, file: #fileID, line: #line)
        let encoded2 = try PostgresDataTranslation.encode(codingPath: [], userInfo: [:], value: [instance, instance], in: .default, file: #fileID, line: #line)
        
        XCTAssertEqual(encoded1.type, .jsonb)
        XCTAssertEqual(encoded2.type, .jsonbArray)
        
        let decoded1 = try PostgresDataTranslation.decode(UnusualType.self, from: .init(bytes: encoded1.value, dataType: encoded1.type, format: encoded1.formatCode, columnName: "", columnIndex: -1), in: .default)
        let decoded2 = try PostgresDataTranslation.decode([UnusualType].self, from: .init(bytes: encoded2.value, dataType: encoded2.type, format: encoded2.formatCode, columnName: "", columnIndex: -1), in: .default)
        
        XCTAssertEqual(decoded1.prop3, instance.prop3)
        XCTAssertEqual(decoded2.count, 2)
    }
    
    func testFluentWorkaroundsDecoding() throws {
        // SQLKit benchmarks already test enum handling
        
        // Text encoding for Decimal
        let decimalBuffer = ByteBuffer(string: Decimal(12345.6789).description)
        var decimalValue: Decimal?
        XCTAssertNoThrow(decimalValue = try PostgresDataTranslation.decode(Decimal.self, from: .init(bytes: decimalBuffer, dataType: .numeric, format: .text, columnName: "", columnIndex: -1), in: .default))
        XCTAssertEqual(decimalValue, Decimal(12345.6789))
        
        // Decoding Double from NUMERIC
        let numericBuffer = PostgresData(numeric: .init(decimal: 12345.6789)).value
        var numericValue: Double?
        XCTAssertNoThrow(numericValue = try PostgresDataTranslation.decode(Double.self, from: .init(bytes: numericBuffer, dataType: .numeric, format: .binary, columnName: "", columnIndex: -1), in: .default))
        XCTAssertEqual(numericValue, Double(Decimal(12345.6789).description))
    }

    var eventLoop: any EventLoop { self.eventLoopGroup.any() }
    var eventLoopGroup: (any EventLoopGroup)!

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

extension Bar: PostgresNonThrowingEncodable, PostgresArrayEncodable, PostgresDecodable, PostgresArrayDecodable {
    func encode(into byteBuffer: inout ByteBuffer, context: PostgresEncodingContext<some PostgresJSONEncoder>) {
        self.rawValue.encode(into: &byteBuffer, context: context)
    }
    
    init(from byteBuffer: inout ByteBuffer, type: PostgresDataType, format: PostgresFormat, context: PostgresDecodingContext<some PostgresJSONDecoder>) throws {
        guard let value = try Self.init(rawValue: Self.RawValue.init(from: &byteBuffer, type: type, format: format, context: context)) else {
            throw PostgresDecodingError.Code.failure
        }
        self = value
    }
    
    static var psqlType: PostgresDataType { .int8 }
    static var psqlFormat: PostgresFormat { .binary }
    static var psqlArrayType: PostgresDataType { .int8Array }
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = env("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ?? .info
        return handler
    }
    return true
}()
