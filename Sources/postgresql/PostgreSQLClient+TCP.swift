import Async
import TCP

extension PostgreSQLClient {
    /// Connects to a Redis server using a TCP socket.
    public static func connect(
        hostname: String = "localhost",
        port: UInt16 = 5432,
        on worker: Worker
    ) throws -> PostgreSQLClient {
        let socket = try TCPSocket(isNonBlocking: true)
        let client = try TCPClient(socket: socket)
        try client.connect(hostname: hostname, port: port)
        return PostgreSQLClient(stream: socket.stream(on: worker), on: worker)
    }
}
