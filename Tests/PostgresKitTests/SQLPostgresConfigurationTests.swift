@testable import PostgresKit
import XCTest

final class SQLPostgresConfigurationTests: XCTestCase {
    func testURLHandling() throws {
        let config1 = try SQLPostgresConfiguration(url: "postgres+tcp://test_username:test_password@test_hostname:9999/test_database?tlsmode=disable")
        XCTAssertEqual(config1.coreConfiguration.database, "test_database")
        XCTAssertEqual(config1.coreConfiguration.password, "test_password")
        XCTAssertEqual(config1.coreConfiguration.username, "test_username")
        XCTAssertEqual(config1.coreConfiguration.host, "test_hostname")
        XCTAssertEqual(config1.coreConfiguration.port, 9999)
        XCTAssertNil(config1.coreConfiguration.unixSocketPath)
        XCTAssertFalse(config1.coreConfiguration.tls.isAllowed)
        XCTAssertFalse(config1.coreConfiguration.tls.isEnforced)

        let config2 = try SQLPostgresConfiguration(url: "postgres+tcp://test_username@test_hostname")
        XCTAssertNil(config2.coreConfiguration.database)
        XCTAssertNil(config2.coreConfiguration.password)
        XCTAssertEqual(config2.coreConfiguration.username, "test_username")
        XCTAssertEqual(config2.coreConfiguration.host, "test_hostname")
        XCTAssertEqual(config2.coreConfiguration.port, SQLPostgresConfiguration.ianaPortNumber)
        XCTAssertNil(config2.coreConfiguration.unixSocketPath)
        XCTAssertTrue(config2.coreConfiguration.tls.isAllowed)
        XCTAssertFalse(config2.coreConfiguration.tls.isEnforced)

        let config3 = try SQLPostgresConfiguration(url: "postgres+uds://test_username:test_password@localhost/tmp/postgres.sock?tlsmode=require#test_database")
        XCTAssertEqual(config3.coreConfiguration.database, "test_database")
        XCTAssertEqual(config3.coreConfiguration.password, "test_password")
        XCTAssertEqual(config3.coreConfiguration.username, "test_username")
        XCTAssertNil(config3.coreConfiguration.host)
        XCTAssertNil(config3.coreConfiguration.port)
        XCTAssertEqual(config3.coreConfiguration.unixSocketPath, "/tmp/postgres.sock")
        XCTAssertTrue(config3.coreConfiguration.tls.isAllowed)
        XCTAssertTrue(config3.coreConfiguration.tls.isEnforced)

        let config4 = try SQLPostgresConfiguration(url: "postgres+uds://test_username@/tmp/postgres.sock")
        XCTAssertNil(config4.coreConfiguration.database)
        XCTAssertNil(config4.coreConfiguration.password)
        XCTAssertEqual(config4.coreConfiguration.username, "test_username")
        XCTAssertNil(config4.coreConfiguration.host)
        XCTAssertNil(config4.coreConfiguration.port)
        XCTAssertEqual(config4.coreConfiguration.unixSocketPath, "/tmp/postgres.sock")
        XCTAssertFalse(config4.coreConfiguration.tls.isAllowed)
        XCTAssertFalse(config4.coreConfiguration.tls.isEnforced)
        
        for modestr in ["tlsmode=false", "tlsmode=verify-full&tlsmode=disable"] {
            let config = try SQLPostgresConfiguration(url: "postgres://u@h?\(modestr)")
            XCTAssertFalse(config.coreConfiguration.tls.isAllowed)
            XCTAssertFalse(config.coreConfiguration.tls.isEnforced)
        }

        for modestr in ["tlsmode=prefer", "tlsmode=allow", "tlsmode=true"] {
            let config = try SQLPostgresConfiguration(url: "postgres://u@h?\(modestr)")
            XCTAssertTrue(config.coreConfiguration.tls.isAllowed)
            XCTAssertFalse(config.coreConfiguration.tls.isEnforced)
        }

        for modestr in ["tlsmode=require", "tlsmode=verify-ca", "tlsmode=verify-full", "tls=verify-full", "ssl=verify-full", "tlsmode=prefer&sslmode=verify-full"] {
            let config = try SQLPostgresConfiguration(url: "postgres://u@h?\(modestr)")
            XCTAssertTrue(config.coreConfiguration.tls.isAllowed)
            XCTAssertTrue(config.coreConfiguration.tls.isEnforced)
        }
        
        XCTAssertNoThrow(try SQLPostgresConfiguration(url:"postgresql://test_username@test_hostname"))
        XCTAssertNoThrow(try SQLPostgresConfiguration(url:"postgresql+tcp://test_username@test_hostname"))
        XCTAssertNoThrow(try SQLPostgresConfiguration(url:"postgresql+uds://test_username@/tmp/postgres.sock"))
        
        XCTAssertThrowsError(try SQLPostgresConfiguration(url: "postgres+tcp://test_hostname"), "should fail when username missing")
        XCTAssertThrowsError(try SQLPostgresConfiguration(url: "postgres+tcp://test_username@test_hostname?tlsmode=absurd"), "should fail when TLS mode invalid")
        XCTAssertThrowsError(try SQLPostgresConfiguration(url: "postgres+uds://localhost/tmp/postgres.sock?tlsmode=require"), "should fail when username missing")
        XCTAssertThrowsError(try SQLPostgresConfiguration(url: "postgres+uds:///tmp/postgres.sock"), "should fail when authority missing")
        XCTAssertThrowsError(try SQLPostgresConfiguration(url: "postgres+uds://username@localhost/"), "should fail when path missing")
        XCTAssertThrowsError(try SQLPostgresConfiguration(url: "postgres+uds://username@remotehost/tmp"), "should fail when authority not localhost or empty")
    }
}
