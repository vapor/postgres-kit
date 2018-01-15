import Async
import Foundation
import XCTest
@testable import PostgreSQL
import TCP

class PostgreSQLClientTests: XCTestCase {
    func testExample() throws {
        let eventLoop = try DefaultEventLoop(label: "codes.vapor.postgresql.client.test")
        let client = try PostgreSQLClient.connect(on: eventLoop)
        let startup = PostgreSQLStartupMessage.versionThree(parameters: ["user": "postgres"])
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

        let requests = PushStream<PostgreSQLMessage>()
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

        let startup = PostgreSQLStartupMessage.versionThree(parameters: ["user": "postgres"])
        requests.push(.startupMessage(startup))

        _ = try promise.future.await(on: eventLoop)
    }

    static var allTests = [
        ("testExample", testExample),
        ("testStreaming", testStreaming),
    ]
}
