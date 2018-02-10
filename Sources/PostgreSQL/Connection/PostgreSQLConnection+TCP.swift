import Async
import TCP

extension PostgreSQLConnection {
    /// Connects to a Redis server using a TCP socket.
    public static func connect(
        hostname: String = "localhost",
        port: UInt16 = 5432,
        on worker: Worker,
        onError: @escaping TCPSocketSink.ErrorHandler
    ) throws -> PostgreSQLConnection {
        let socket = try TCPSocket(isNonBlocking: true)
        let client = try TCPClient(socket: socket)
        try client.connect(hostname: hostname, port: port)
        let stream = socket.stream(on: worker, onError: onError)
        return PostgreSQLConnection(stream: stream, on: worker)
    }
}
