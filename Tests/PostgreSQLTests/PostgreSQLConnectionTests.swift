import Foundation
import XCTest
import NIO
import NIOOpenSSL
import PostgreSQL
import Core

class PostgreSQLConnectionTests: XCTestCase {
    let defaultTimeout = 5.0
    func testVersion() throws {
        let client = try PostgreSQLConnection.makeTest(transport: .cleartext)
        let results = try client.simpleQuery("SELECT version();").wait()
        try XCTAssert(results[0].firstValue(forColumn: "version")?.decode(String.self).contains("10.") == true)
    }
    
    func testUnverifiedSSLConnection() throws {
        let client = try PostgreSQLConnection.makeTest(transport: .unverifiedTLS)
        let results = try client.simpleQuery("SELECT version();").wait()
        try XCTAssert(results[0].firstValue(forColumn: "version")?.decode(String.self).contains("10.") == true)
    }

    func testSelectTypes() throws {
        let client = try PostgreSQLConnection.makeTest(transport: .cleartext)
        let results = try client.query("select * from pg_type;").wait()
        if results.count > 350 {
            let name = try results[128].firstValue(forColumn: "typname")?.decode(String.self)
            XCTAssert(name != "")
        } else {
            XCTFail("Results count not large enough: \(results.count)")
        }
    }

    func testParse() throws {
        let client = try PostgreSQLConnection.makeTest(transport: .cleartext)
        let query = """
        select * from "pg_type" where "typlen" = $1 or "typlen" = $2
        """
        let rows = try client.query(query, [1, 2]).wait()

        for row in rows {
            try XCTAssert(
                row.firstValue(forColumn: "typlen")?.decode(Int.self) == 1 ||
                row.firstValue(forColumn: "typlen")?.decode(Int.self) == 2
            )
        }
    }

    func testTypes() throws {
        let client = try PostgreSQLConnection.makeTest(transport: .cleartext)
        let createQuery = """
        create table kitchen_sink (
            "smallint" smallint,
            "integer" integer,
            "bigint" bigint,
            "decimal" decimal,
            "numeric" numeric,
            "real" real,
            "double" double precision,
            "varchar" varchar(64),
            "char" char(4),
            "text" text,
            "bytea" bytea,
            "timestamp" timestamp,
            "date" date,
            "time" time,
            "boolean" boolean,
            "point" point
            -- "line" line,
            -- "lseg" lseg,
            -- "box" box,
            -- "path" path,
            -- "polygon" polygon,
            -- "circle" circle,
            -- "cidr" cidr,
            -- "inet" inet,
            -- "macaddr" macaddr,
            -- "bit" bit(16),
            -- "uuid" uuid
        );
        """
        _ = try client.query("drop table if exists kitchen_sink;").wait()
        let createResult = try client.query(createQuery).wait()
        XCTAssertEqual(createResult.count, 0)

        let insertQuery = """
        insert into kitchen_sink values (
            1, -- "smallint" smallint
            2, -- "integer" integer
            3, -- "bigint" bigint
            4, -- "decimal" decimal
            5.3, -- "numeric" numeric
            6, -- "real" real
            7, -- "double" double precision
            '9', -- "varchar" varchar(64)
            '10', -- "char" char(4)
            '11', -- "text" text
            '12', -- "bytea" bytea
            now(), -- "timestamp" timestamp
            current_date, -- "date" date
            localtime, -- "time" time
            true, -- "boolean" boolean
            point(13.5,14) -- "point" point,
            -- "line" line,
            -- "lseg" lseg,
            -- "box" box,
            -- "path" path,
            -- "polygon" polygon,
            -- "circle" circle,
            -- "cidr" cidr,
            -- "inet" inet,
            -- "macaddr" macaddr,
            -- "bit" bit(16),
            -- "uuid" uuid
        );
        """
        let insertResult = try client.query(insertQuery).wait()
        XCTAssertEqual(insertResult.count, 0)
        let queryResult = try client.query("select * from kitchen_sink").wait()
        if queryResult.count == 1 {
            let row = queryResult[0]
            try XCTAssertEqual(row.firstValue(forColumn: "smallint")?.decode(Int16.self), 1)
            try XCTAssertEqual(row.firstValue(forColumn: "integer")?.decode(Int32.self), 2)
            try XCTAssertEqual(row.firstValue(forColumn: "bigint")?.decode(Int64.self), 3)
            try XCTAssertEqual(row.firstValue(forColumn: "decimal")?.decode(String.self), "4")
            try XCTAssertEqual(row.firstValue(forColumn: "real")?.decode(Float.self), 6)
            try XCTAssertEqual(row.firstValue(forColumn: "double")?.decode(Double.self), 7)
            try XCTAssertEqual(row.firstValue(forColumn: "varchar")?.decode(String.self), "9")
            try XCTAssertEqual(row.firstValue(forColumn: "char")?.decode(String.self), "10  ")
            try XCTAssertEqual(row.firstValue(forColumn: "text")?.decode(String.self), "11")
            try XCTAssertEqual(row.firstValue(forColumn: "bytea")?.decode(Data.self), Data([0x31, 0x32]))
            try XCTAssertEqual(row.firstValue(forColumn: "boolean")?.decode(Bool.self), true)
            try XCTAssertNotNil(row.firstValue(forColumn: "timestamp")?.decode(Date.self))
            try XCTAssertNotNil(row.firstValue(forColumn: "date")?.decode(Date.self))
            try XCTAssertNotNil(row.firstValue(forColumn: "time")?.decode(Date.self))
            try XCTAssertEqual(row.firstValue(forColumn: "point")?.decode(PostgreSQLPoint.self), PostgreSQLPoint(x: 13.5, y: 14))
        } else {
            XCTFail("query result count is: \(queryResult.count)")
        }
    }

    func testParameterizedTypes() throws {
        let client = try PostgreSQLConnection.makeTest(transport: .cleartext)
        let createQuery = """
        create table kitchen_sink (
            "smallint" smallint,
            "integer" integer,
            "bigint" bigint,
            "decimal" decimal,
            "numeric" numeric,
            "real" real,
            "double" double precision,
            "varchar" varchar(64),
            "char" char(4),
            "text" text,
            "bytea" bytea,
            "timestamp" timestamp,
            "date" date,
            "time" time,
            "boolean" boolean,
            "point" point,
            "uuid" uuid,
            "array" point[]
            -- "line" line,
            -- "lseg" lseg,
            -- "box" box,
            -- "path" path,
            -- "polygon" polygon,
            -- "circle" circle,
            -- "cidr" cidr,
            -- "inet" inet,
            -- "macaddr" macaddr,
            -- "bit" bit(16),
        );
        """
        _ = try client.query("drop table if exists kitchen_sink;").wait()
        let createResult = try client.query(createQuery).wait()
        XCTAssertEqual(createResult.count, 0)

        let insertQuery = """
        insert into kitchen_sink values (
            $1, -- "smallint" smallint
            $2, -- "integer" integer
            $3, -- "bigint" bigint
            $4::numeric, -- "decimal" decimal
            $5, -- "numeric" numeric
            $6, -- "real" real
            $7, -- "double" double precision
            $8, -- "varchar" varchar(64)
            $9, -- "char" char(4)
            $10, -- "text" text
            $11, -- "bytea" bytea
            $12, -- "timestamp" timestamp
            $13, -- "date" date
            $14, -- "time" time
            $15, -- "boolean" boolean
            $16, -- "point" point
            $17, -- "uuid" uuid
            '{"(1,2)","(3,4)"}' -- "array" point[]
            -- "line" line,
            -- "lseg" lseg,
            -- "box" box,
            -- "path" path,
            -- "polygon" polygon,
            -- "circle" circle,
            -- "cidr" cidr,
            -- "inet" inet,
            -- "macaddr" macaddr,
            -- "bit" bit(16),
        );
        """

        var params: [PostgreSQLDataConvertible] = []
        params += Int16(1) // smallint
        params += Int32(2) // integer
        params += Int64(3) // bigint
        params += String("123456789.0123456789") // decimal
        params += Double(5) // numeric
        params += Float(6) // real
        params += Double(7) // double
        params += String("8") // varchar
        params += String("9") // char
        params += String("10") // text
        params += Data([0x31, 0x32]) // bytea
        params += Date() // timestamp
        params += Date() // date
        params += Date() // time
        params += Bool(true) // boolean
        params += PostgreSQLPoint(x: 11.4, y: 12) // point
        params += UUID() // new uuid
        // params.append([1,2,3] as [Int]) // new array

        let insertResult = try client.query(insertQuery, params).wait()
        XCTAssertEqual(insertResult.count, 0)

        let parameterizedResult = try client.query("select * from kitchen_sink").wait()
        if parameterizedResult.count == 1 {
            let row = parameterizedResult[0]
            try XCTAssertEqual(row.firstValue(forColumn: "smallint")?.decode(Int16.self), 1)
            try XCTAssertEqual(row.firstValue(forColumn: "integer")?.decode(Int32.self), 2)
            try XCTAssertEqual(row.firstValue(forColumn: "bigint")?.decode(Int64.self), 3)
            try XCTAssertEqual(row.firstValue(forColumn: "decimal")?.decode(String.self), "123456789.0123456789")
            try XCTAssertEqual(row.firstValue(forColumn: "real")?.decode(Float.self), 6)
            try XCTAssertEqual(row.firstValue(forColumn: "double")?.decode(Double.self), 7)
            try XCTAssertEqual(row.firstValue(forColumn: "varchar")?.decode(String.self), "8")
            try XCTAssertEqual(row.firstValue(forColumn: "char")?.decode(String.self), "9   ")
            try XCTAssertEqual(row.firstValue(forColumn: "text")?.decode(String.self), "10")
            try XCTAssertEqual(row.firstValue(forColumn: "bytea")?.decode(Data.self), Data([0x31, 0x32]))
            try XCTAssertEqual(row.firstValue(forColumn: "boolean")?.decode(Bool.self), true)
            try XCTAssertNotNil(row.firstValue(forColumn: "timestamp")?.decode(Date.self))
            try XCTAssertNotNil(row.firstValue(forColumn: "date")?.decode(Date.self))
            try XCTAssertNotNil(row.firstValue(forColumn: "time")?.decode(Date.self))
            try XCTAssertEqual(row.firstValue(forColumn: "point")?.decode(String.self), "(11.4,12.0)")
            try XCTAssertNotNil(row.firstValue(forColumn: "uuid")?.decode(UUID.self))
            try XCTAssertEqual(row.firstValue(forColumn: "array")?.decode([PostgreSQLPoint].self).first?.x, 1.0)
        } else {
            XCTFail("parameterized result count is: \(parameterizedResult.count)")
        }
    }

    func testStruct() throws {
        struct Hello: PostgreSQLJSONCustomConvertible, Codable {
            var message: String
        }

        let client = try PostgreSQLConnection.makeTest(transport: .cleartext)
        _ = try client.query("drop table if exists foo;").wait()
        let createResult = try client.query("create table foo (id integer, dict jsonb);").wait()
        XCTAssertEqual(createResult.count, 0)
        let insertResult = try client.query("insert into foo values ($1, $2);", [
            Int32(1), Hello(message: "hello, world")
        ]).wait()

        XCTAssertEqual(insertResult.count, 0)
        let parameterizedResult = try client.query("select * from foo").wait()
        if parameterizedResult.count == 1 {
            let row = parameterizedResult[0]
            try XCTAssertEqual(row.firstValue(forColumn: "id")?.decode(Int.self), 1)
            try XCTAssertEqual(row.firstValue(forColumn: "dict")?.decode(Hello.self).message, "hello, world")
        } else {
            XCTFail("parameterized result count is: \(parameterizedResult.count)")
        }
    }

    func testNull() throws {
        let client = try PostgreSQLConnection.makeTest(transport: .cleartext)
        _ = try client.query("drop table if exists nulltest;").wait()
        let createResult = try client.query("create table nulltest (i integer not null, d timestamp);").wait()
        XCTAssertEqual(createResult.count, 0)
        let insertResult = try client.query("insert into nulltest  (i, d) VALUES ($1, $2)", [
            PostgreSQLData(.int2, binary: Data([0x00, 0x01])),
            PostgreSQLData(null: .timestamp),
        ]).wait()
        XCTAssertEqual(insertResult.count, 0)
        let parameterizedResult = try client.query("select * from nulltest").wait()
        XCTAssertEqual(parameterizedResult.count, 1)
    }

    func testGH24() throws {
        /// PREPARE
        let client = try PostgreSQLConnection.makeTest(transport: .cleartext)
        _ = try client.query("""
        DROP TABLE IF EXISTS "acronym+category"
        """).wait()
        _ = try client.query("""
        DROP TABLE IF EXISTS "categories"
        """).wait()
        _ = try client.query("""
        DROP TABLE IF EXISTS "acronyms"
        """).wait()
        _ = try client.query("""
        DROP TABLE IF EXISTS "users"
        """).wait()

        /// CREATE
        let _ = try client.query("""
        CREATE TABLE "users" ("id" UUID PRIMARY KEY, "name" TEXT NOT NULL, "username" TEXT NOT NULL)
        """).wait()
        let _ = try client.query("""
        CREATE TABLE "acronyms" ("id" BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY, "short" TEXT NOT NULL, "long" TEXT NOT NULL, "userID" UUID NOT NULL, FOREIGN KEY ("userID") REFERENCES "users" ("id"), FOREIGN KEY ("userID") REFERENCES "users" ("id"))
        """).wait()
        let _ = try client.query("""
        CREATE TABLE "categories" ("id" BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY, "name" TEXT NOT NULL)
        """).wait()
        let _ = try client.query("""
        CREATE TABLE "acronym+category" ("id" UUID PRIMARY KEY, "acronymID" BIGINT NOT NULL, "categoryID" BIGINT NOT NULL, FOREIGN KEY ("acronymID") REFERENCES "acronyms" ("id"), FOREIGN KEY ("categoryID") REFERENCES "categories" ("id"), FOREIGN KEY ("acronymID") REFERENCES "acronyms" ("id"), FOREIGN KEY ("categoryID") REFERENCES "categories" ("id"))
        """).wait()

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

    // https://github.com/vapor/postgresql/issues/46
    func testGH46() throws {
        struct Overview {
            var platform: String
            var identifier: String
            var count: Int
        }

        let connection = try PostgreSQLConnection.makeTest(transport: .cleartext)
        _ = try connection.simpleQuery("DROP TABLE IF EXISTS apps").wait()
        _ = try connection.simpleQuery("CREATE TABLE apps (id INT, platform TEXT, identifier TEXT)").wait()
        _ = try connection.simpleQuery("INSERT INTO apps VALUES (1, 'a', 'b')").wait()
        _ = try connection.simpleQuery("INSERT INTO apps VALUES (2, 'c', 'd')").wait()
        _ = try connection.simpleQuery("INSERT INTO apps VALUES (3, 'a', 'd')").wait()
        _ = try connection.simpleQuery("INSERT INTO apps VALUES (4, 'a', 'b')").wait()
        let overviews = try connection.query("SELECT platform, identifier, COUNT(id) as count FROM apps GROUP BY platform, identifier").map(to: [Overview].self) { data in
            return try data.map { row in
                return try Overview(
                    platform: row.firstValue(forColumn: "platform")!.decode(String.self),
                    identifier: row.firstValue(forColumn: "identifier")!.decode(String.self),
                    count: row.firstValue(forColumn: "count")!.decode(Int.self)
                )
            }
        }.wait()
        XCTAssertEqual(overviews.count, 3)
    }
    
    func testDML() throws {
        let conn = try PostgreSQLConnection.makeTest(transport: .cleartext)
        _ = try conn.simpleQuery(.drop(ifExists: true, "users")).wait()
        _ = try conn.simpleQuery(.create("users", columns: [
            .column("id", .init(.int8, primaryKey: true, generatedIdentity: true)),
            .column("name", .text)
        ])).wait()
        defer { _ = try? conn.simpleQuery(.drop("users")).wait() }
        
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
            predicate: .predicate("name", .equal, .bind("vapor"))
        )).wait()
        XCTAssertEqual(search.count, 1)
        
        try conn.query(.select(["id", "name"], from: "users")) { row in
            print(row)
        }.wait()
    }

    static var allTests = [
        ("testUnverifiedSSLConnection", testUnverifiedSSLConnection),
        ("testVersion", testVersion),
        ("testSelectTypes", testSelectTypes),
        ("testParse", testParse),
        ("testTypes", testTypes),
        ("testParameterizedTypes", testParameterizedTypes),
        ("testStruct", testStruct),
        ("testNull", testNull),
        ("testGH24", testGH24),
//        ("testNotifyAndListen", testNotifyAndListen),
//        ("testNotifyAndListenOnMultipleChannels", testNotifyAndListenOnMultipleChannels),
//        ("testUnlisten", testUnlisten),
        ("testURLParsing", testURLParsing),
        ("testGH46", testGH46),
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
