import Async

/// A PostgreSQL frontend client.
final class PostgreSQLClient {
    /// Handles enqueued redis commands and responses.
    private let queueStream: QueueStream<PostgreSQLMessage, PostgreSQLMessage>

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

    /// Sends `RedisData` to the server.
    func send(_ data: PostgreSQLMessage) -> Future<PostgreSQLMessage> {
        return queueStream.enqueue(data)
    }
}
