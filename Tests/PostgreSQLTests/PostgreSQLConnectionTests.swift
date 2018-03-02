import Async
import Foundation
import XCTest
import PostgreSQL

class PostgreSQLConnectionTests: XCTestCase {
    func testVersion() throws {
        let client = try PostgreSQLConnection.makeTest()
        let results = try client.simpleQuery("SELECT version();").wait()
        try XCTAssert(results[0]["version"]?.decode(String.self).contains("10.") == true)
    }

    func testSelectTypes() throws {
        let client = try PostgreSQLConnection.makeTest()
        let results = try client.query("select * from pg_type;").wait()
        if results.count > 350 {
            let name = try results[128]["typname"]?.decode(String.self)
            XCTAssert(name != "")
        } else {
            XCTFail("Results count not large enough: \(results.count)")
        }
    }

    func testParse() throws {
        let client = try PostgreSQLConnection.makeTest()
        let query = """
        select * from "pg_type" where "typlen" = $1 or "typlen" = $2
        """
        let rows = try client.query(query, [1, 2]).wait()

        for row in rows {
            try XCTAssert(row["typlen"]?.decode(Int.self) == 1 || row["typlen"]?.decode(Int.self) == 2)
        }
    }

    func testTypes() throws {
        let client = try PostgreSQLConnection.makeTest()
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
            try XCTAssertEqual(row["smallint"]?.decode(Int16.self), 1)
            try XCTAssertEqual(row["integer"]?.decode(Int32.self), 2)
            try XCTAssertEqual(row["bigint"]?.decode(Int64.self), 3)
            try XCTAssertEqual(row["decimal"]?.decode(String.self), "4")
            try XCTAssertEqual(row["real"]?.decode(Float.self), 6)
            try XCTAssertEqual(row["double"]?.decode(Double.self), 7)
            try XCTAssertEqual(row["varchar"]?.decode(String.self), "9")
            try XCTAssertEqual(row["char"]?.decode(String.self), "10  ")
            try XCTAssertEqual(row["text"]?.decode(String.self), "11")
            try XCTAssertEqual(row["bytea"]?.decode(Data.self), Data([0x31, 0x32]))
            try XCTAssertEqual(row["boolean"]?.decode(Bool.self), true)
            try XCTAssertNotNil(row["timestamp"]?.decode(Date.self))
            try XCTAssertNotNil(row["date"]?.decode(Date.self))
            try XCTAssertNotNil(row["time"]?.decode(Date.self))
            try XCTAssertEqual(row["point"]?.decode(PostgreSQLPoint.self), PostgreSQLPoint(x: 13.5, y: 14))
        } else {
            XCTFail("query result count is: \(queryResult.count)")
        }
    }

    func testParameterizedTypes() throws {
        let client = try PostgreSQLConnection.makeTest()
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

        var params: [PostgreSQLDataCustomConvertible] = []
        params += Int16(1) // smallint
        params += Int32(2) // integer
        params += Int64(3) // bigint
        params += String("123456789.123456789") // decimal
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
            try XCTAssertEqual(row["smallint"]?.decode(Int16.self), 1)
            try XCTAssertEqual(row["integer"]?.decode(Int32.self), 2)
            try XCTAssertEqual(row["bigint"]?.decode(Int64.self), 3)
            try XCTAssertEqual(row["decimal"]?.decode(String.self), "123456789.123456789")
            try XCTAssertEqual(row["real"]?.decode(Float.self), 6)
            try XCTAssertEqual(row["double"]?.decode(Double.self), 7)
            try XCTAssertEqual(row["varchar"]?.decode(String.self), "8")
            try XCTAssertEqual(row["char"]?.decode(String.self), "9   ")
            try XCTAssertEqual(row["text"]?.decode(String.self), "10")
            try XCTAssertEqual(row["bytea"]?.decode(Data.self), Data([0x31, 0x32]))
            try XCTAssertEqual(row["boolean"]?.decode(Bool.self), true)
            try XCTAssertNotNil(row["timestamp"]?.decode(Date.self))
            try XCTAssertNotNil(row["date"]?.decode(Date.self))
            try XCTAssertNotNil(row["time"]?.decode(Date.self))
            try XCTAssertEqual(row["point"]?.decode(String.self), "(11.4,12.0)")
            try XCTAssertNotNil(row["uuid"]?.decode(UUID.self))
            try XCTAssertEqual(row["array"]?.decode([PostgreSQLPoint].self).first?.x, 1.0)
        } else {
            XCTFail("parameterized result count is: \(parameterizedResult.count)")
        }
    }

    func testStruct() throws {
        struct Hello: PostgreSQLJSONCustomConvertible, Codable {
            var message: String
        }

        let client = try PostgreSQLConnection.makeTest()
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
            try XCTAssertEqual(row["id"]?.decode(Int.self), 1)
            try XCTAssertEqual(row["dict"]?.decode(Hello.self).message, "hello, world")
        } else {
            XCTFail("parameterized result count is: \(parameterizedResult.count)")
        }
    }

    func testNull() throws {
        let client = try PostgreSQLConnection.makeTest()
        _ = try client.query("drop table if exists nulltest;").wait()
        let createResult = try client.query("create table nulltest (i integer not null, d timestamp);").wait()
        XCTAssertEqual(createResult.count, 0)
        let insertResult = try client.query("insert into nulltest  (i, d) VALUES ($1, $2)", [
            PostgreSQLData(type: .int2, format: .binary, data: Data([0x00, 0x01])),
            PostgreSQLData(type: .timestamp, format: .binary, data: nil),
        ]).wait()
        XCTAssertEqual(insertResult.count, 0)
        let parameterizedResult = try client.query("select * from nulltest").wait()
        XCTAssertEqual(parameterizedResult.count, 1)
    }

    static var allTests = [
        ("testVersion", testVersion),
        ("testSelectTypes", testSelectTypes),
        ("testParse", testParse),
        ("testTypes", testTypes),
        ("testParameterizedTypes", testParameterizedTypes),
        ("testStruct", testStruct),
        ("testNull", testNull),
    ]
}

extension PostgreSQLConnection {
    /// Creates a test event loop and psql client.
    static func makeTest() throws -> PostgreSQLConnection {
        let group = MultiThreadedEventLoopGroup(numThreads: 1)
        let client = try PostgreSQLConnection.connect(on: wrap(group.next())) { error in
            XCTFail("\(error)")
        }.wait()
        _ = try client.authenticate(username: "postgres").wait()
        return client
    }
}

func +=<T>(lhs: inout [T], rhs: T) {
    lhs.append(rhs)
}
