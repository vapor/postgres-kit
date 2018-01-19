import Async

/// A PostgreSQL frontend client.
public final class PostgreSQLConnection {
    /// Handles enqueued redis commands and responses.
    private let queueStream: QueueStream<PostgreSQLMessage, PostgreSQLMessage>

    /// If non-nil, will log queries.
    public var logger: PostgreSQLLogger?

    /// Creates a new Redis client on the provided data source and sink.
    init<Stream>(stream: Stream, on worker: Worker) where Stream: ByteStream {
        let queueStream = QueueStream<PostgreSQLMessage, PostgreSQLMessage>()

        let serializerStream = PostgreSQLMessageSerializer().stream(on: worker)
        let parserStream = PostgreSQLMessageParser().stream(on: worker)

        stream.stream(to: parserStream)
            .stream(to: queueStream)
            .stream(to: serializerStream)
            .output(to: stream)

        self.queueStream = queueStream
    }

    /// Sends `PostgreSQLMessage` to the server.
    func send(_ messages: [PostgreSQLMessage], onResponse: @escaping (PostgreSQLMessage) throws -> ()) -> Future<Void> {
        return queueStream.enqueue(messages) { message in
            switch message {
            case .readyForQuery: return true
            case .error(let e): throw e
            case .notice(let n):
                print(n)
                return false
            default:
                try onResponse(message)
                return false // request until ready for query
            }
        }
    }

    /// Sends `PostgreSQLMessage` to the server.
    func send(_ message: [PostgreSQLMessage]) -> Future<[PostgreSQLMessage]> {
        var responses: [PostgreSQLMessage] = []
        return send(message) { response in
            responses.append(response)
        }.map(to: [PostgreSQLMessage].self) {
            return responses
        }
    }

    /// Closes this client.
    public func close() {
        queueStream.close()
    }
}

infix operator !!
internal func !!<T>(lhs: Optional<T>, rhs: String) -> T {
    switch lhs {
    case .none: fatalError(rhs)
    case .some(let w): return w
    }
}
