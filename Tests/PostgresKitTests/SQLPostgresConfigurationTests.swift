import PostgresKit
import Testing

extension AllSuites {
@Suite
struct SQLPostgresConfigurationTests {
    @Test
    func urlHandling() throws {
        let config1 = try SQLPostgresConfiguration(url: "postgres+tcp://test_username:test_password@test_hostname:9999/test_database?tlsmode=disable")
        #expect(config1.coreConfiguration.database == "test_database")
        #expect(config1.coreConfiguration.password == "test_password")
        #expect(config1.coreConfiguration.username == "test_username")
        #expect(config1.coreConfiguration.host == "test_hostname")
        #expect(config1.coreConfiguration.port == 9999)
        #expect(config1.coreConfiguration.unixSocketPath == nil)
        #expect(!config1.coreConfiguration.tls.isAllowed)
        #expect(!config1.coreConfiguration.tls.isEnforced)

        let config2 = try SQLPostgresConfiguration(url: "postgres+tcp://test_username@test_hostname")
        #expect(config2.coreConfiguration.database == nil)
        #expect(config2.coreConfiguration.password == nil)
        #expect(config2.coreConfiguration.username == "test_username")
        #expect(config2.coreConfiguration.host == "test_hostname")
        #expect(config2.coreConfiguration.port == SQLPostgresConfiguration.ianaPortNumber)
        #expect(config2.coreConfiguration.unixSocketPath == nil)
        #expect(config2.coreConfiguration.tls.isAllowed)
        #expect(!config2.coreConfiguration.tls.isEnforced)

        let config3 = try SQLPostgresConfiguration(url: "postgres+uds://test_username:test_password@localhost/tmp/postgres.sock?tlsmode=require#test_database")
        #expect(config3.coreConfiguration.database == "test_database")
        #expect(config3.coreConfiguration.password == "test_password")
        #expect(config3.coreConfiguration.username == "test_username")
        #expect(config3.coreConfiguration.host == nil)
        #expect(config3.coreConfiguration.port == nil)
        #expect(config3.coreConfiguration.unixSocketPath == "/tmp/postgres.sock")
        #expect(config3.coreConfiguration.tls.isAllowed)
        #expect(config3.coreConfiguration.tls.isEnforced)

        let config4 = try SQLPostgresConfiguration(url: "postgres+uds://test_username@/tmp/postgres.sock")
        #expect(config4.coreConfiguration.database == nil)
        #expect(config4.coreConfiguration.password == nil)
        #expect(config4.coreConfiguration.username == "test_username")
        #expect(config4.coreConfiguration.host == nil)
        #expect(config4.coreConfiguration.port == nil)
        #expect(config4.coreConfiguration.unixSocketPath == "/tmp/postgres.sock")
        #expect(!config4.coreConfiguration.tls.isAllowed)
        #expect(!config4.coreConfiguration.tls.isEnforced)

        for modestr in ["tlsmode=false", "tlsmode=verify-full&tlsmode=disable"] {
            let config = try SQLPostgresConfiguration(url: "postgres://u@h?\(modestr)")
            #expect(!config.coreConfiguration.tls.isAllowed)
            #expect(!config.coreConfiguration.tls.isEnforced)
        }

        for modestr in ["tlsmode=prefer", "tlsmode=allow", "tlsmode=true"] {
            let config = try SQLPostgresConfiguration(url: "postgres://u@h?\(modestr)")
            #expect(config.coreConfiguration.tls.isAllowed)
            #expect(!config.coreConfiguration.tls.isEnforced)
        }

        for modestr in ["tlsmode=require", "tlsmode=verify-ca", "tlsmode=verify-full", "tls=verify-full", "ssl=verify-full", "tlsmode=prefer&sslmode=verify-full"] {
            let config = try SQLPostgresConfiguration(url: "postgres://u@h?\(modestr)")
            #expect(config.coreConfiguration.tls.isAllowed)
            #expect(config.coreConfiguration.tls.isEnforced)
        }
        
        #expect(throws: Never.self) { try SQLPostgresConfiguration(url: "postgresql://test_username@test_hostname") }
        #expect(throws: Never.self) { try SQLPostgresConfiguration(url: "postgresql+tcp://test_username@test_hostname") }
        #expect(throws: Never.self) { try SQLPostgresConfiguration(url: "postgresql+uds://test_username@/tmp/postgres.sock") }

        #expect(throws: (any Error).self, "should fail when username missing") { try SQLPostgresConfiguration(url: "postgres+tcp://test_hostname") }
        #expect(throws: (any Error).self, "should fail when TLS mode invalid") { try SQLPostgresConfiguration(url: "postgres+tcp://test_username@test_hostname?tlsmode=absurd") }
        #expect(throws: (any Error).self, "should fail when username missing") { try SQLPostgresConfiguration(url: "postgres+uds://localhost/tmp/postgres.sock?tlsmode=require") }
        #expect(throws: (any Error).self, "should fail when authority missing") { try SQLPostgresConfiguration(url: "postgres+uds:///tmp/postgres.sock") }
        #expect(throws: (any Error).self, "should fail when path missing") { try SQLPostgresConfiguration(url: "postgres+uds://username@localhost/") }
        #expect(throws: (any Error).self, "should fail when authority not localhost or empty") { try SQLPostgresConfiguration(url: "postgres+uds://username@remotehost/tmp") }
    }

    init() {
        #expect(isLoggingConfigured)
    }
}
}
