import Async
import Foundation
import XCTest
@testable import PostgreSQL
import TCP

class PostgreSQLClientTests: XCTestCase {
    func testExample() throws {
        let eventLoop = try DefaultEventLoop(label: "codes.vapor.postgresql.client.test")
        let client = try PostgreSQLClient.connect(on: eventLoop)
        let startup = PostgreSQLStartupMessage.versionThree(parameters: ["user": "tanner"])
        let res = try client.send(.startupMessage(startup)).await(on: eventLoop)
        print(res)
    }

    func testStreaming() throws {
        let socket = try TCPSocket(isNonBlocking: true)
        let client = try TCPClient(socket: socket)
        try client.connect(hostname: "localhost", port: 5432)

        let eventLoop = try DefaultEventLoop(label: "codes.vapor.postgresql.client.test")
        let byteStream = client.socket.stream(on: eventLoop)
        let parserStream = PostgreSQLMessageParser().stream(on: eventLoop)
        let serializerStream = PostgreSQLMessageSerializer().stream(on: eventLoop)

        let startup = PostgreSQLStartupMessage.versionThree(parameters: ["user": "tanner"])
        let requests = StaticStream<PostgreSQLMessage>(data: [.startupMessage(startup)])

        requests.stream(to: serializerStream)
            .output(to: byteStream)

        let promise = Promise(Void.self)

        byteStream.stream(to: parserStream).drain { message, upstream in
            print(message)
            switch message {
            case .readyForQuery: promise.complete()
            case .errorResponse(let e): promise.fail(e)
            default: break
            }
        }.catch { error in
            XCTFail("\(error)")
        }.finally {
            print("Closed")
        }.upstream!.request(count: .max)

        _ = try promise.future.await(on: eventLoop)
    }

    static var allTests = [
        ("testExample", testExample),
        ("testStreaming", testStreaming),
    ]
}

public final class StaticStream<O>: Async.OutputStream, ConnectionContext {
    public typealias Output = O

    public var downstream: AnyInputStream<Output>?
    public var data: [Output]

    public init(data: [Output]) {
        self.data = data.reversed()
    }

    public func connection(_ event: ConnectionEvent) {
        switch event {
        case .cancel:
            data = []
        case .request(var count):
            stream: while count > 0 {
                count -= 1
                if let data = self.data.popLast() {
                    downstream!.next(data)
                } else {
                    // out of data
                    break stream
                }
            }
        }
    }

    public func output<S>(to inputStream: S) where S: Async.InputStream, S.Input == Output {
        self.downstream = .init(inputStream)
        inputStream.connect(to: self)
    }

}
