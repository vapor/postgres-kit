import Foundation
import Logging
import NIOCore
import PostgresNIO
import SQLKitBenchmark
import Testing
@testable import PostgresKit

extension AllSuites {

@Suite
struct PostgresKitTests {
    @Test
    func sqlKitBenchmark() async throws {
        let conn = try await PostgresConnection.test(on: self.eventLoop)

        await #expect(throws: Never.self) {
            let benchmark = SQLBenchmarker(on: conn.sql())

            try await benchmark.runAllTests()
        }
        try await conn.close()
    }

    @Test
    func leak() async throws {
        struct Foo: Codable {
            let id: String
            let description: String?
            let latitude: Double, longitude: Double
            let created_by: String, created_at: Date
            let modified_by: String, modified_at: Date
        }
        
        let conn = try await PostgresConnection.test(on: self.eventLoop)
        let db = conn.sql()

        await #expect(throws: Never.self) {
            try await db.drop(table: "foos").ifExists().run()
            try await db.create(table: "foos")
                .column("id", type: .text, .primaryKey(autoIncrement: false))
                .column("description", type: .text)
                .column("latitude", type: .custom(SQLRaw("DOUBLE PRECISION")))
                .column("longitude", type: .custom(SQLRaw("DOUBLE PRECISION")))
                .column("created_by", type: .text)
                .column("created_at", type: .timestamp)
                .column("modified_by", type: .text)
                .column("modified_at", type: .timestamp)
                .run()

            for i in 0..<2_000 {
                let zipcode = Foo(
                    id: UUID().uuidString,
                    description: "test \(i)",
                    latitude: .random(in: 0...100), longitude: .random(in: 0...100),
                    created_by: "test", created_at: .now,
                    modified_by: "test", modified_at: .now
                )
                try await db.insert(into: "foos").model(zipcode).run()
            }
        }
        try? await db.drop(table: "foos").ifExists().run()
        try await conn.close()
    }

    @Test
    func arrayEncoding() async throws {
        let conn = try await PostgresConnection.test(on: self.eventLoop)

        struct Foo: Codable {
            var bar: Int
        }

        await #expect(throws: Never.self) {
            let foos: [Foo] = [.init(bar: 1), .init(bar: 2)]
            try await conn.sql().raw("SELECT \(bind: foos)::JSONB[] as \(ident: "foos")").run()
        }
        try await conn.close()
    }

    @Test
    func decodeModelWithNil() async throws {
        let conn = try await PostgresConnection.test(on: self.eventLoop)

        await #expect(throws: Never.self) {
            let rows = try await conn.sql().raw("SELECT \(literal: "foo")::text as \(ident: "foo"), \(SQLLiteral.null) as \(ident: "bar"), \(literal: "baz")::text as \(ident: "baz")").all()
            let row = rows[0]

            struct Test: Codable {
                var foo: String
                var bar: String?
                var baz: String?
            }

            let test = try row.decode(model: Test.self)
            #expect(test.foo == "foo")
            #expect(test.bar == nil)
            #expect(test.baz == "baz")
        }
        try await conn.close()
    }

    @Test
    func eventLoopGroupSQL() async throws {
        var configuration = SQLPostgresConfiguration.test
        configuration.searchPath = ["foo", "bar", "baz"]
        let source = PostgresConnectionSource(sqlConfiguration: configuration)
        let pool = EventLoopGroupConnectionPool(source: source, on: MultiThreadedEventLoopGroup.singleton)
        let db = pool.database(logger: .init(label: "test")).sql()

        await #expect(throws: Never.self) {
            try await #expect(db.raw("SELECT version()").all().count == 1)
        }
        try await pool.shutdownAsync()
    }

    @Test
    func integerArrayEncoding() async throws {
        let connection = try await PostgresConnection.test(on: self.eventLoop)

        await #expect(throws: Never.self) {
            let sql = connection.sql()
            _ = try await sql.raw("DROP TABLE IF EXISTS \(ident: "foo")").run()
            try await sql.withSession { db in
                _ = try await db.create(table: "foo").column("bar", type: .custom(SQLRaw("bigint[]")), .notNull).run()
                _ = try await db.insert(into: "foo").columns("bar").values(SQLBind([Bar]())).run()
                let rows = try await connection.query("SELECT bar FROM foo", logger: connection.logger).collect()
                #expect(rows.count == 1)
                #expect(rows.first?.count == 1)
                #expect(rows.first?.first?.dataType == Bar.psqlArrayType)
                #expect(try rows.first?.first?.decode([Bar].self) == [Bar]())
            }
        }
        try await connection.close()
    }
    
    /// Tests dealing with encoding of values whose `encode(to:)` implementation calls one of the `superEncoder()`
    /// methods (most notably the implementation of `Codable` for Fluent's `Fields`, which we can't directly test
    /// at this layer).
    @Test
    func valuesThatUseSuperEncoder() throws {
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
        
        #expect(encoded1.type == .jsonb)
        #expect(encoded2.type == .jsonbArray)

        let decoded1 = try PostgresDataTranslation.decode(UnusualType.self, from: .init(bytes: encoded1.value, dataType: encoded1.type, format: encoded1.formatCode, columnName: "", columnIndex: -1), in: .default)
        let decoded2 = try PostgresDataTranslation.decode([UnusualType].self, from: .init(bytes: encoded2.value, dataType: encoded2.type, format: encoded2.formatCode, columnName: "", columnIndex: -1), in: .default)
        
        #expect(decoded1.prop3 == instance.prop3)
        #expect(decoded2.count == 2)
    }

    @Test
    func fluentWorkaroundsDecoding() throws {
        // SQLKit benchmarks already test enum handling
        
        // Text encoding for Decimal
        let decimalBuffer = ByteBuffer(string: Decimal(12345.6789).description)
        var decimalValue: Decimal?
        #expect(throws: Never.self) { decimalValue = try PostgresDataTranslation.decode(Decimal.self, from: .init(bytes: decimalBuffer, dataType: .numeric, format: .text, columnName: "", columnIndex: -1), in: .default) }
        #expect(decimalValue == Decimal(12345.6789))

        // Decoding Double from NUMERIC
        let numericBuffer = PostgresData(numeric: .init(decimal: 12345.6789)).value
        var numericValue: Double?
        #expect(throws: Never.self) { numericValue = try PostgresDataTranslation.decode(Double.self, from: .init(bytes: numericBuffer, dataType: .numeric, format: .binary, columnName: "", columnIndex: -1), in: .default) }
        #expect(numericValue == Double(Decimal(12345.6789).description))
    }

    @Test
    func urlWorkaroundDecoding() throws {
        let url = URL(string: "https://user:pass@www.example.com:8080/path/to/endpoint?query=value#fragment")!
        
        let encodedNormal = try PostgresDataTranslation.encode(codingPath: [], userInfo: [:], value: url, in: .default, file: #fileID, line: #line)
        #expect(encodedNormal.value?.getString(at: 0, length: encodedNormal.value?.readableBytes ?? 0) == url.absoluteString)

        let encodedBroken = try PostgresDataTranslation.encode(codingPath: [], userInfo: [:], value: "\"\(url.absoluteString)\"", in: .default, file: #fileID, line: #line)
        
        #expect(try PostgresDataTranslation.decode(URL.self, from: .init(with: encodedNormal), in: .default) == url)
        #expect(try PostgresDataTranslation.decode(URL.self, from: .init(with: encodedBroken), in: .default) == url)
    }

    /// This test cares that:
    ///
    /// 1. The Swift type (i.e. `Foo`) is mentioned in the error's debug description.
    /// 2. The underlying error is included.
    @Test
    func errorHandlingWhenDecodingNestedDictionary() throws {
        struct Foo: Codable {
            struct Bar: Codable { let id: Int }
            let bar: Bar
        }

        let error = try #require(throws: DecodingError.self) {
            _ = try PostgresDataTranslation.decode(Foo.self, from: .init(bytes: .init(integer: 0), dataType: .int8, format: .binary, columnName: "", columnIndex: 0), in: .default)
        }

        let context = try #require({ if case .dataCorrupted(let context) = error { context } else { nil } }())
        #expect(context.debugDescription == "Unable to interpret value of PSQL type BIGINT as Swift type Foo: [0000000000000000](8 bytes)")

        let underContext = try #require({ if case .dataCorrupted(let context2) = context.underlyingError as? DecodingError { context2 } else { nil } }())
        #expect(underContext.debugDescription == "Dictionary containers must be JSON-encoded")
    }

    @Test
    func encodingArraysContainingNilValues() async throws {
        let encoded1 = try PostgresDataTranslation.encode(codingPath: [], userInfo: [:], value: [-1, nil, nil, nil] as [Int?], in: .default, file: #fileID, line: #line)
        #expect(encoded1.type == .int8Array && encoded1.array?.count == 4)
        #expect(encoded1.array?.dropFirst(0).first?.type == .int8 && encoded1.array?.dropFirst(0).first?.int == -1)
        #expect(encoded1.array?.dropFirst(1).first?.type == .int8 && encoded1.array?.dropFirst(1).first?.value == nil)
        #expect(encoded1.array?.dropFirst(2).first?.type == .int8 && encoded1.array?.dropFirst(2).first?.value == nil)
        #expect(encoded1.array?.dropFirst(3).first?.type == .int8 && encoded1.array?.dropFirst(3).first?.value == nil)
        let encoded2 = try PostgresDataTranslation.encode(codingPath: [], userInfo: [:], value: [nil, nil, nil, nil] as [Int?], in: .default, file: #fileID, line: #line)
        #expect(encoded2.type == .int8Array && encoded2.array?.count == 4)
        #expect(encoded2.array?.dropFirst(0).first?.type == .int8 && encoded2.array?.dropFirst(0).first?.value == nil)
        #expect(encoded2.array?.dropFirst(1).first?.type == .int8 && encoded2.array?.dropFirst(1).first?.value == nil)
        #expect(encoded2.array?.dropFirst(2).first?.type == .int8 && encoded2.array?.dropFirst(2).first?.value == nil)
        #expect(encoded2.array?.dropFirst(3).first?.type == .int8 && encoded2.array?.dropFirst(3).first?.value == nil)
        let encoded3 = try PostgresDataTranslation.encode(codingPath: [], userInfo: [:], value: [.one, nil, nil, nil] as [Bar?], in: .default, file: #fileID, line: #line)
        #expect(encoded3.type == .int8Array && encoded3.array?.count == 4)
        #expect(encoded3.array?.dropFirst(0).first?.type == .int8 && encoded3.array?.dropFirst(0).first?.int == 0)
        #expect(encoded3.array?.dropFirst(1).first?.type == .int8 && encoded3.array?.dropFirst(1).first?.value == nil)
        #expect(encoded3.array?.dropFirst(2).first?.type == .int8 && encoded3.array?.dropFirst(2).first?.value == nil)
        #expect(encoded3.array?.dropFirst(3).first?.type == .int8 && encoded3.array?.dropFirst(3).first?.value == nil)
        let encoded4 = try PostgresDataTranslation.encode(codingPath: [], userInfo: [:], value: [nil, nil, nil, nil] as [Bar?], in: .default, file: #fileID, line: #line)
        #expect(encoded4.type == .int8Array && encoded4.array?.count == 4)
        #expect(encoded4.array?.dropFirst(0).first?.type == .int8 && encoded4.array?.dropFirst(0).first?.value == nil)
        #expect(encoded4.array?.dropFirst(1).first?.type == .int8 && encoded4.array?.dropFirst(1).first?.value == nil)
        #expect(encoded4.array?.dropFirst(2).first?.type == .int8 && encoded4.array?.dropFirst(2).first?.value == nil)
        #expect(encoded4.array?.dropFirst(3).first?.type == .int8 && encoded4.array?.dropFirst(3).first?.value == nil)

        let connection = try await PostgresConnection.test(on: self.eventLoop)

        await #expect(throws: Never.self) {
            let sql = connection.sql()
            _ = try await sql.raw("DROP TABLE IF EXISTS \(ident: "foo")").run()
            try await sql.withSession { db in
                _ = try await db.create(table: "foo").column("bar", type: .custom(SQLRaw("bigint[]")), .notNull).run()
                _ = try await db.insert(into: "foo").columns("bar").values(SQLBind([-1, nil, nil, nil] as [Int?])).values(SQLBind([nil, nil, nil, nil] as [Int?])).run()
                _ = try await db.insert(into: "foo").columns("bar").values(SQLBind([.one, nil, nil, nil] as [Bar?])).values(SQLBind([nil, nil, nil, nil] as [Bar?])).run()
                let rows = try await db.select().column("bar").from("foo").all(decodingColumn: "bar", as: [Int?].self)
                #expect(rows.dropFirst(0).first == [-1, nil, nil, nil])
                #expect(rows.dropFirst(1).first == [nil, nil, nil, nil])
                #expect(rows.dropFirst(2).first == [0, nil, nil, nil])
                #expect(rows.dropFirst(3).first == [nil, nil, nil, nil])
            }
        }
        try await connection.close()
    }

    var eventLoop: any EventLoop {
        MultiThreadedEventLoopGroup.singleton.any()
    }

    init() {
        #expect(isLoggingConfigured)
    }
}

}

extension PostgresCell {
    fileprivate init(with data: PostgresData) {
        self.init(bytes: data.value, dataType: data.type, format: data.formatCode, columnName: "", columnIndex: -1)
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
