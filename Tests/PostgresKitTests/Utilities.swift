import Foundation
import Logging
import NIOCore
import PostgresKit
import PostgresNIO
import Testing

extension PostgresConnection {
    static func test(on eventLoop: any EventLoop) async throws -> PostgresConnection {
        try await PostgresConnectionSource(sqlConfiguration: .test).makeConnection(
            logger: .init(label: "vapor.codes.postgres-kit.test"),
            on: eventLoop
        ).get()
    }
}

extension SQLPostgresConfiguration {
    static var test: Self {
        .init(
            hostname: env("POSTGRES_HOSTNAME") ?? "localhost",
            port: env("POSTGRES_PORT").flatMap(Int.init) ?? Self.ianaPortNumber,
            username: env("POSTGRES_USER") ?? "test_username",
            password: env("POSTGRES_PASSWORD") ?? "test_password",
            database: env("POSTGRES_DB") ?? "test_database",
            tls: .disable
        )
    }
}

func env(_ name: String) -> String? {
    ProcessInfo.processInfo.environment[name]
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { QuickLogHandler(label: $0, level: env("LOG_LEVEL").flatMap { .init(rawValue: $0) } ?? .info) }
    return true
}()

struct QuickLogHandler: LogHandler {
    private let label: String
    var logLevel = Logger.Level.info, metadataProvider = LoggingSystem.metadataProvider, metadata = Logger.Metadata()
    subscript(metadataKey key: String) -> Logger.Metadata.Value? { get { self.metadata[key] } set { self.metadata[key] = newValue } }
    init(label: String, level: Logger.Level) { (self.label, self.logLevel) = (label, level) }
    func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        print("\(self.timestamp()) \(level) \(self.label):\(self.prettify(metadata ?? [:]).map { " \($0)" } ?? "") [\(source)] \(message)")
    }
    private func prettify(_ metadata: Logger.Metadata) -> String? {
        self.metadata.merging(self.metadataProvider?.get() ?? [:]) { $1 }.merging(metadata) { $1 }.sorted { $0.0 < $1.0 }.map { "\($0)=\($1.mvDesc)" }.joined(separator: " ")
    }
    private func timestamp() -> String { .init(unsafeUninitializedCapacity: 255) { buffer in
        var timestamp = time(nil)
        return localtime(&timestamp).map { strftime(buffer.baseAddress!, buffer.count, "%Y-%m-%dT%H:%M:%S%z", $0) } ?? buffer.initialize(fromContentsOf: "<unknown>".utf8)
    } }
}
extension Logger.MetadataValue {
    var mvDesc: String { switch self {
        case .dictionary(let dict): "[\(dict.mapValues(\.mvDesc).lazy.sorted { $0.0 < $1.0 }.map { "\($0): \($1)" }.joined(separator: ", "))]"
        case .array(let list): "[\(list.map(\.mvDesc).joined(separator: ", "))]"
        case .string(let str): #""\#(str)""#
        case .stringConvertible(let repr): switch repr {
            case let repr as Bool: "\(repr)"
            case let repr as any FixedWidthInteger: "\(repr)"
            case let repr as any BinaryFloatingPoint: "\(repr)"
            default: #""\#(String(describing: repr))""#
        }
    } }
}

@Suite(.serialized)
struct AllSuites {}
