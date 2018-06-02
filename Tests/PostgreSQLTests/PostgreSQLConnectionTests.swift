import PostgreSQL
import XCTest

class PostgreSQLConnectionTests: XCTestCase {
    struct VersionMetadata: Decodable {
        var version: String
    }
    
    func testVersion() throws {
        let client = try PostgreSQLConnection.makeTest(transport: .cleartext)
        let results = try client.simpleQuery("SELECT version();", decoding: VersionMetadata.self).wait()
        XCTAssertTrue(results[0].version.contains("10."))
    }

    func testUnverifiedSSLConnection() throws {
        let client = try PostgreSQLConnection.makeTest(transport: .unverifiedTLS)
        let results = try client.simpleQuery("SELECT version();", decoding: VersionMetadata.self).wait()
        XCTAssertTrue(results[0].version.contains("10."))
    }

    func testSelectTypes() throws {
        // 1247.typisdefined: 0x01 (BOOLEAN)
        // 1247.typbasetype: 0x00000000 (OID)
        // 1247.typnotnull: 0x00 (BOOLEAN)
        // 1247.typcategory: 0x42 (CHAR)
        // 1247.typname: 0x626f6f6c (NAME)
        // 1247.typbyval: 0x01 (BOOLEAN)
        // 1247.typrelid: 0x00000000 (OID)
        // 1247.typalign: 0x63 (CHAR)
        // 1247.typndims: 0x00000000 (INTEGER)
        // 1247.typacl: null
        // 1247.typsend: 0x00000985 (REGPROC)
        // 1247.typmodout: 0x00000000 (REGPROC)
        // 1247.typstorage: 0x70 (CHAR)
        // 1247.typispreferred: 0x01 (BOOLEAN)
        // 1247.typinput: 0x000004da (REGPROC)
        // 1247.typoutput: 0x000004db (REGPROC)
        // 1247.typlen: 0x0001 (SMALLINT)
        // 1247.typcollation: 0x00000000 (OID)
        // 1247.typdefaultbin: null
        // 1247.typelem: 0x00000000 (OID)
        // 1247.typnamespace: 0x0000000b (OID)
        // 1247.typtype: 0x62 (CHAR)
        // 1247.typowner: 0x0000000a (OID)
        // 1247.typdefault: null
        // 1247.typtypmod: 0xffffffff (INTEGER)
        // 1247.typarray: 0x000003e8 (OID)
        // 1247.typreceive: 0x00000984 (REGPROC)
        // 1247.typmodin: 0x00000000 (REGPROC)
        // 1247.typanalyze: 0x00000000 (REGPROC)
        // 1247.typdelim: 0x2c (CHAR)
        struct PGType: Decodable {
            var typname: String
            var typnamespace: UInt32
            var typowner: UInt32
            var typlen: Int16
            var typbyval: Bool
            var typtype: Char
            var typcategory: Char
            var typispreferred: Bool
            var typisdefined: Bool
            var typdelim: Char
            var typrelid: UInt32
            var typelem: UInt32
            var typarray: UInt32
            var typinput: Regproc
            var typoutput: Regproc
            var typreceive: Regproc
            var typsend: Regproc
            var typmodin: Regproc
            var typmodout: Regproc
            var typanalyze: Regproc
            var typalign: Char
            var typstorage: Char
            var typnotnull: Bool
            var typbasetype: UInt32
            var typtypmod: Int
            var typndims: Int
            var typcollation: UInt32
//            var typdefaultbin: String?
//            var typdefault: String?
//            var typacl: String?
        }
        let client = try PostgreSQLConnection.makeTest(transport: .cleartext)
        do {
            // simple query
            let results = try client.simpleQuery(.select([.all], from: "pg_type"), decoding: PGType.self).wait()
            XCTAssert(results.count >= 350, "Results count not large enough: \(results.count)")
        }
        do {
            // query: default
            let results = try client.query(.select([.all], from: "pg_type"), decoding: PGType.self).wait()
            XCTAssert(results.count >= 350, "Results count not large enough: \(results.count)")
        }
        do {
            // query: binary
            let results = try client.query(.select([.all], from: "pg_type"), resultFormat: .binary, decoding: PGType.self).wait()
            XCTAssert(results.count >= 350, "Results count not large enough: \(results.count)")
        }
        do {
            // query: text
            let results = try client.query(.select([.all], from: "pg_type"), resultFormat: .text, decoding: PGType.self).wait()
            XCTAssert(results.count >= 350, "Results count not large enough: \(results.count)")
        }
    }
    
    struct Foo: Codable {
        var id: Int?
        var dict: Hello
    }
    
    struct Hello: Codable {
        var message: String
    }

    func testStruct() throws {
        let client = try PostgreSQLConnection.makeTest(transport: .cleartext)

        _ = try client.query(.create(table: "foo", columns: [.column("id", .columnType("INT")), .column("dict", .columnType("JSONB"))])).wait()
        defer { _ = try? client.simpleQuery(.drop(table: "foo")).wait() }

        let hello = Hello(message: "Hello, world!")
        _ = try client.query(.insert(into: "foo", values: ["id": .bind(1), "dict": .bind(hello)])).wait()

        let fetch = try client.query(.select([.all], from: "foo"), decoding: Foo.self).wait()
        switch fetch.count {
        case 1:
            XCTAssertEqual(fetch[0].id, 1)
            XCTAssertEqual(fetch[0].dict.message, "Hello, world!")
        default: XCTFail("invalid row count")
        }
    }

    func testNull() throws {
        let conn = try PostgreSQLConnection.makeTest(transport: .cleartext)
        
        _ = try conn.query(.create(table: "nulltest", columns: [
            .column("i", .columnType("INT", attributes: ["NOT NULL"])),
            .column("d", .columnType("TIMESTAMP"))
        ])).wait()
        defer { _ = try? conn.simpleQuery(.drop(table: "nulltest")).wait() }
        
        _ = try conn.query(.insert(into: "nulltest", values: ["i": .bind(1), "d": .bind(Date?.none)])).wait()
    }

    func testGH24() throws {
        /// PREPARE
        let client = try PostgreSQLConnection.makeTest(transport: .cleartext)

        /// CREATE
        let _ = try client.query("""
        CREATE TABLE "users" ("id" UUID PRIMARY KEY, "name" TEXT NOT NULL, "username" TEXT NOT NULL)
        """).wait()
        defer { _ = try! client.simpleQuery(.drop(table: "users")).wait() }
        let _ = try client.query("""
        CREATE TABLE "acronyms" ("id" BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY, "short" TEXT NOT NULL, "long" TEXT NOT NULL, "userID" UUID NOT NULL, FOREIGN KEY ("userID") REFERENCES "users" ("id"), FOREIGN KEY ("userID") REFERENCES "users" ("id"))
        """).wait()
        defer { _ = try! client.simpleQuery(.drop(table: "acronyms")).wait() }
        let _ = try client.query("""
        CREATE TABLE "categories" ("id" BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY, "name" TEXT NOT NULL)
        """).wait()
        defer { _ = try! client.simpleQuery(.drop(table: "categories")).wait() }
        let _ = try client.query("""
        CREATE TABLE "acronym+category" ("id" UUID PRIMARY KEY, "acronymID" BIGINT NOT NULL, "categoryID" BIGINT NOT NULL, FOREIGN KEY ("acronymID") REFERENCES "acronyms" ("id"), FOREIGN KEY ("categoryID") REFERENCES "categories" ("id"), FOREIGN KEY ("acronymID") REFERENCES "acronyms" ("id"), FOREIGN KEY ("categoryID") REFERENCES "categories" ("id"))
        """).wait()
        defer { _ = try! client.simpleQuery(.drop(table: "acronym+category")).wait() }

        /// INSERT
        let userUUID = UUID()
        let _ = try client.query("""
        INSERT INTO "users" ("id", "name", "username") VALUES ($1, $2, $3)
        """, [userUUID, "Vapor Test", "vapor"]).wait()
        let _ = try client.query("""
        INSERT INTO "acronyms" ("id", "userID", "short", "long") VALUES ($1, $2, $3, $4)
        """, [1, userUUID, "ilv", "i love vapor"]).wait()
        let _ = try client.query("""
        INSERT INTO "categories" ("id", "name") VALUES ($1, $2);
        """, [1, "all"]).wait()


        /// SELECT
        let acronyms = client.query("""
        SELECT "acronyms".* FROM "acronyms" WHERE ("acronyms"."id" = $1) LIMIT 1 OFFSET 0
        """, [1])
        let categories = client.query("""
        SELECT "categories".* FROM "categories" WHERE ("categories"."id" = $1) LIMIT 1 OFFSET 0
        """, [1])

        _ = try acronyms.wait()
        _ = try categories.wait()
    }

//    func testNotifyAndListen() throws {
//        let completionHandlerExpectation1 = expectation(description: "first completion handler called")
//        let completionHandlerExpectation2 = expectation(description: "final completion handler called")
//        let notifyConn = try PostgreSQLConnection.makeTest()
//        let listenConn = try PostgreSQLConnection.makeTest()
//        let channelName = "Fooze"
//        let messageText = "Bar"
//        let finalMessageText = "Baz"
//
//        try listenConn.listen(channelName) { text in
//            if text == messageText {
//                completionHandlerExpectation1.fulfill()
//            } else if text == finalMessageText {
//                completionHandlerExpectation2.fulfill()
//            }
//        }.catch({ err in XCTFail("error \(err)") })
//
//        try notifyConn.notify(channelName, message: messageText).wait()
//        try notifyConn.notify(channelName, message: finalMessageText).wait()
//
//        waitForExpectations(timeout: defaultTimeout)
//        notifyConn.close()
//        listenConn.close()
//    }
//
//    func testNotifyAndListenOnMultipleChannels() throws {
//        let completionHandlerExpectation1 = expectation(description: "first completion handler called")
//        let completionHandlerExpectation2 = expectation(description: "final completion handler called")
//        let notifyConn = try PostgreSQLConnection.makeTest()
//        let listenConn = try PostgreSQLConnection.makeTest()
//        let channelName = "Fooze"
//        let channelName2 = "Foozalz"
//        let messageText = "Bar"
//        let finalMessageText = "Baz"
//
//        try listenConn.listen(channelName) { text in
//            if text == messageText {
//                completionHandlerExpectation1.fulfill()
//            }
//        }.catch({ err in XCTFail("error \(err)") })
//
//        try listenConn.listen(channelName2) { text in
//            if text == finalMessageText {
//                completionHandlerExpectation2.fulfill()
//            }
//        }.catch({ err in XCTFail("error \(err)") })
//
//        try notifyConn.notify(channelName, message: messageText).wait()
//        try notifyConn.notify(channelName2, message: finalMessageText).wait()
//
//        waitForExpectations(timeout: defaultTimeout)
//        notifyConn.close()
//        listenConn.close()
//    }
//
//    func testUnlisten() throws {
//        let unlistenHandlerExpectation = expectation(description: "unlisten completion handler called")
//
//        let listenHandlerExpectation = expectation(description: "listen completion handler called")
//
//        let notifyConn = try PostgreSQLConnection.makeTest()
//        let listenConn = try PostgreSQLConnection.makeTest()
//        let channelName = "Foozers"
//        let messageText = "Bar"
//
//        try listenConn.listen(channelName) { text in
//            if text == messageText {
//                listenHandlerExpectation.fulfill()
//            }
//        }.catch({ err in XCTFail("error \(err)") })
//
//        try notifyConn.notify(channelName, message: messageText).wait()
//        try notifyConn.unlisten(channelName, unlistenHandler: {
//            unlistenHandlerExpectation.fulfill()
//        }).wait()
//        waitForExpectations(timeout: defaultTimeout)
//        notifyConn.close()
//        listenConn.close()
//    }

    func testURLParsing() throws {
        let databaseURL = "postgres://username:password@localhost:5432/database"
        let config = try PostgreSQLDatabaseConfig(url: databaseURL)
        XCTAssertEqual("\(config.serverAddress)", "ServerAddress(storage: PostgreSQL.PostgreSQLConnection.ServerAddress.Storage.tcp(hostname: \"localhost\", port: 5432))")
        XCTAssertEqual(config.username, "username")
        XCTAssertEqual(config.password, "password")
        XCTAssertEqual(config.database, "database")
    }

    struct Overview: Codable {
        var platform: String
        var identifier: String
        var count: Int
    }
    
    // https://github.com/vapor/postgresql/issues/46
    func testGH46() throws {
        let conn = try PostgreSQLConnection.makeTest(transport: .cleartext)
        _ = try conn.simpleQuery("CREATE TABLE apps (id INT, platform TEXT, identifier TEXT)").wait()
        defer { _ = try? conn.simpleQuery(.drop(table: "apps")).wait() }
        _ = try conn.simpleQuery("INSERT INTO apps VALUES (1, 'a', 'b')").wait()
        _ = try conn.simpleQuery("INSERT INTO apps VALUES (2, 'c', 'd')").wait()
        _ = try conn.simpleQuery("INSERT INTO apps VALUES (3, 'a', 'd')").wait()
        _ = try conn.simpleQuery("INSERT INTO apps VALUES (4, 'a', 'b')").wait()
        let overviews = try conn.query("SELECT platform, identifier, COUNT(id) as count FROM apps GROUP BY platform, identifier", decoding: Overview.self).wait()
        XCTAssertEqual(overviews.count, 3)
    }
    
    func testDataDecoder() throws {
        enum Toy: String, Codable {
            case bologna, plasticBag
        }
        
        let toy = try PostgreSQLDataDecoder().decode(Toy.self, from: PostgreSQLData(.text, text: "bologna"))
        print(toy)
        
        struct Pet: Codable {
            var name: String
            var toys: [Toy]
        }
        
        let pet = try! PostgreSQLDataDecoder().decode(Pet.self, from: PostgreSQLData(.jsonb, binary: [0x01] + JSONEncoder().encode(Pet(name: "Zizek", toys: [.bologna, .plasticBag]))))
        print(pet)
    }
    
    func testRowDecoder() throws {
        enum Toy: String, Codable {
            case bologna, plasticBag
        }
        
        struct Pet: Codable {
            var name: String
            var toys: [Toy]
        }
        
        struct User: Codable {
            var id: UUID?
            var name: String
            var pet: Pet
            var toy: Toy?
        }
        
        let row: [PostgreSQLColumn: PostgreSQLData] = try [
            PostgreSQLColumn(tableOID: 5, name: "id"): PostgreSQLData(.uuid, binary: Data([0x54, 0xd6, 0xfc, 0x55, 0x82, 0x9b, 0x48, 0x29, 0x87, 0xc9, 0x50, 0xe4, 0xd4, 0xd9, 0x5c, 0x3b])),
            PostgreSQLColumn(tableOID: 5, name: "name"): PostgreSQLData(.text, binary: Data("tanner".utf8)),
            PostgreSQLColumn(tableOID: 5, name: "pet"): PostgreSQLData(.jsonb, binary: [0x01] + JSONEncoder().encode(Pet(name: "Zizek", toys: [.bologna, .plasticBag]))),
            PostgreSQLColumn(tableOID: 5, name: "toy"): PostgreSQLData(.text, text: "bologna"),
        ]
        let user = try! PostgreSQLRowDecoder().decode(User.self, from: row, tableOID: 5)
        print(user)
    }
    
    func testRowCodableNested() throws {
        enum Toy: String, Codable {
            case bologna, plasticBag
        }
        
        enum UserType: String, Codable {
            case admin
        }
        
        struct Pet: Codable {
            var name: String
            var toys: [Toy]
        }
        
        struct User: Codable {
            var id: UUID?
            var name: String
            var type: UserType
            var pet: Pet
        }
        
        let userA = User(id: UUID(), name: "Tanner", type: .admin, pet: .init(name: "Zizek", toys: [.bologna]))
        let row = try PostgreSQLRowEncoder().encode(userA, tableOID: 5)
        print(row)
        let userB = try PostgreSQLRowDecoder().decode(User.self, from: row, tableOID: 5)
        print(userB)
    }
    
    func testRowCodableTypes() throws {
        let conn = try PostgreSQLConnection.makeTest(transport: .cleartext)
        _ = try! conn.simpleQuery(.drop(ifExists: true, table: "types")).wait()
        _ = try conn.simpleQuery(.create( table: "types", columns: [
            .column("id", .columnType("BIGINT", attributes: ["PRIMARY KEY", "GENERATED BY DEFAULT AS IDENTITY"])),
            .column("bool", .columnType("BOOL")),
            .column("string", .columnType("TEXT")),
            .column("int", .columnType("BIGINT")),
            .column("int8", .columnType("CHAR")),
            .column("int16", .columnType("SMALLINT")),
            .column("int32", .columnType("INT")),
            .column("int64", .columnType("BIGINT")),
            .column("uint", .columnType("BIGINT")),
            .column("uint8", .columnType("CHAR")),
            .column("uint16", .columnType("SMALLINT")),
            .column("uint32", .columnType("INT")),
            .column("uint64", .columnType("BIGINT")),
            .column("double", .columnType("DOUBLE PRECISION")),
            .column("float", .columnType("FLOAT")),
            .column("date", .columnType("TIMESTAMP")),
            .column("decimal", .columnType("JSONB")),
        ])).wait()
        //defer { _ = try! conn.simpleQuery(.drop("types")).wait() }
        
        struct Types: Codable {
            var bool: Bool
            var string: String
            var int: Int
            var int8: Int8
            var int16: Int16
            var int32: Int32
            var int64: Int64
            var uint: UInt
            var uint8: UInt8
            var uint16: UInt16
            var uint32: UInt32
            var uint64: UInt64
            var double: Double
            var float: Float
            var date: Date
            var decimal: Decimal
        }
        
        let typesA = Types(bool: true, string: "hello", int: 1, int8: 2, int16: 3, int32: 4, int64: 5, uint: 6, uint8: 7, uint16: 8, uint32: 9, uint64: 10, double: 13.37, float: 3.14, date: Date(), decimal: .init(-1.234))
        _ = try conn.query(.insert(into: "types", values: SQLRowEncoder().encode(typesA))).wait()
        let rows = try conn.query(.select([.all], from: "types")).wait()
        switch rows.count {
        case 1:
            let typesB = try PostgreSQLRowDecoder().decode(Types.self, from: rows[0])
            XCTAssertEqual(typesA.bool, typesB.bool)
            XCTAssertEqual(typesA.string, typesB.string)
            XCTAssertEqual(typesA.int, typesB.int)
            XCTAssertEqual(typesA.int8, typesB.int8)
            XCTAssertEqual(typesA.int16, typesB.int16)
            XCTAssertEqual(typesA.int32, typesB.int32)
            XCTAssertEqual(typesA.int64, typesB.int64)
            XCTAssertEqual(typesA.uint, typesB.uint)
            XCTAssertEqual(typesA.uint8, typesB.uint8)
            XCTAssertEqual(typesA.uint16, typesB.uint16)
            XCTAssertEqual(typesA.uint32, typesB.uint32)
            XCTAssertEqual(typesA.uint64, typesB.uint64)
            XCTAssertEqual(typesA.double, typesB.double)
            XCTAssertEqual(typesA.float, typesB.float)
            XCTAssertEqual(typesA.date, typesB.date)
            XCTAssertEqual(typesA.decimal, typesB.decimal)
        default: XCTFail("Invalid row count")
        }
    }
    
    func testDML() throws {
        let conn = try PostgreSQLConnection.makeTest(transport: .cleartext)
        _ = try conn.simpleQuery(.create(table: "users", columns: [
            .column("id", .columnType("BIGINT", attributes: ["PRIMARY KEY", "GENERATED BY DEFAULT AS IDENTITY"])),
            .column("name", .columnType("TEXT"))
        ])).wait()
        defer { _ = try? conn.simpleQuery(.drop(table: "users")).wait() }
        
        let save = try conn.query(.dml(
            statement: .insert,
            table: "users",
            columns: [
                "name": .bind("vapor")
            ]
        )).wait()
        XCTAssertEqual(save.count, 0)

        let search = try conn.query(.dml(
            statement: .select,
            table: "users",
            keys: [.all],
            predicates: [.predicate("name", .equal, .bind("vapor"))]
        )).wait()
        XCTAssertEqual(search.count, 1)
        
        try conn.query(.select(["id", "name"], from: "users")) { row in
            print(row)
        }.wait()
    }
    
    func testDMLNestedType() throws {
        let conn = try PostgreSQLConnection.makeTest(transport: .cleartext)
        _ = try conn.simpleQuery(.create(table: "users", columns: [
            .column("id", .columnType("BIGINT", attributes: ["PRIMARY KEY", "GENERATED BY DEFAULT AS IDENTITY"])),
            .column("name", .columnType("NAME")),
            .column("pet", .columnType("JSONB"))
        ])).wait()
        defer { _ = try? conn.simpleQuery(.drop(table: "users")).wait() }
        
        struct Pet: Encodable {
            var name: String
        }
        
        let save = try conn.query(.dml(
            statement: .insert,
            table: "users",
            columns: [
                "name": .bind("vapor"),
                "pet": .bind(Pet(name: "Zizek"))
            ]
        )).wait()
        XCTAssertEqual(save.count, 0)
        
        let search = try conn.query(.select([.all], from: "users", where: [.predicate("name", .equal, .bind("vapor"))]
        )).wait()
        XCTAssertEqual(search.count, 1)
        
        try conn.query(.select(["id", "name", "pet"], from: "users")) { row in
            print(row)
        }.wait()
    }
    
    // https://github.com/vapor/postgresql/issues/63
    func testTimeTz() throws {
        let conn = try PostgreSQLConnection.makeTest(transport: .cleartext)
        _ = try conn.simpleQuery(.create(table: "timetest", columns: [
            .column("timestamptz", .columnType("TIMESTAMPTZ"))
        ])).wait()
        defer { _ = try? conn.simpleQuery(.drop(table: "timetest")).wait() }
        
        struct Time: Codable, Equatable {
            var timestamptz: Date
        }
        
        let time = Time(timestamptz: .init())
        _ = try conn.query(.insert(into: "timetest", values: SQLRowEncoder().encode(time))).wait()
        
        let fetch = try conn.query(.select([.all], from: "timetest"), decoding: Time.self).wait()
        switch fetch.count {
        case 1:
            XCTAssertEqual(fetch[0], time)
        default: XCTFail("invalid row count")
        }
    }
    
    func testListen() throws {
        let conn = try PostgreSQLConnection.makeTest(transport: .cleartext)
        let done = conn.listen("foo") { message in
            XCTAssertEqual(message, "hi")
            return true
        }
        do {
            let conn = try PostgreSQLConnection.makeTest(transport: .cleartext)
            _ = try conn.notify("foo", message: "hi").wait()
        }
        try done.wait()
    }

    static var allTests = [
        ("testVersion", testVersion),
        ("testTimeTz", testTimeTz),
    ]
}

extension PostgreSQLConnection {
    /// Creates a test event loop and psql client over ssl.
    static func makeTest(transport: PostgreSQLConnection.TransportConfig) throws -> PostgreSQLConnection {
        #if Xcode
        return try _makeTest(hostname: "localhost", port: transport.isTLS ? 5433 : 5432, password: "vapor_password", transport: transport)
        #else
        return try _makeTest(hostname: transport.isTLS ? "tls" : "cleartext", port: 5432, password: "vapor_password", transport: transport)
        #endif
    }

    /// Creates a test connection.
    private static func _makeTest(hostname: String, port: Int, password: String? = nil, transport: PostgreSQLConnection.TransportConfig = .cleartext) throws -> PostgreSQLConnection {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let client = try PostgreSQLConnection.connect(hostname: hostname, port: port, transport: transport, on: group) { error in
            XCTFail("\(error)")
        }.wait()
        _ = try client.authenticate(username: "vapor_username", database: "vapor_database", password: password).wait()
        return client
    }
}

func +=<T>(lhs: inout [T], rhs: T) {
    lhs.append(rhs)
}
