import Async

/// A PostgreSQL frontend client.
public final class PostgreSQLConnection {
    /// Handles enqueued redis commands and responses.
    private let queueStream: AsymmetricQueueStream<PostgreSQLMessage, PostgreSQLMessage>

    /// If non-nil, will log queries.
    public var logger: PostgreSQLLogger?

    /// Creates a new Redis client on the provided data source and sink.
    init<Stream>(stream: Stream, on worker: Worker) where Stream: ByteStream {
        let queueStream = AsymmetricQueueStream<PostgreSQLMessage, PostgreSQLMessage>()

        let serializerStream = PostgreSQLMessageSerializer().stream(on: worker)
        let parserStream = PostgreSQLMessageParser().stream(on: worker)

        stream.stream(to: parserStream)
            .stream(to: queueStream)
            .stream(to: serializerStream)
            .output(to: stream)

        self.queueStream = queueStream
    }

    /// Sends `PostgreSQLMessage` to the server.
    func send(_ message: [PostgreSQLMessage], onResponse: @escaping (PostgreSQLMessage) throws -> ()) -> Future<Void> {
        return queueStream.enqueue(message) { message in
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

/// Enqueues a single input and waits for multiple output.
/// This is useful for situations where one request can lead
/// to multiple responses.
public final class AsymmetricQueueStream<I, O>: Stream, ConnectionContext {
    /// See `InputStream.Input`
    public typealias Input = I

    /// See `OutputStream.Output`
    public typealias Output = O

    /// Current upstream output stream.
    private var upstream: ConnectionContext?

    /// Current downstrema input stream.
    private var downstream: AnyInputStream<Output>?

    /// Current downstream demand.
    private var downstreamDemand: UInt

    /// Queued output.
    private var queuedOutput: [Output]

    /// Queued input.
    private var queuedInput: [AsymmetricQueueStreamInput<Input>]

    /// Current input being handled.
    private var currentInput: AsymmetricQueueStreamInput<Input>?

    /// Create a new `AsymmetricQueueStream`.
    public init() {
        self.downstreamDemand = 0
        self.queuedOutput = []
        self.queuedInput = []
    }

    /// Enqueue the supplied output, specifying a closure that will determine
    /// when the Input received is ready.
    public func enqueue(_ output: [Output], onInput: @escaping (Input) throws -> Bool) -> Future<Void> {
        let input = AsymmetricQueueStreamInput(onInput: onInput)
        self.queuedInput.insert(input, at: 0)
        for o in output {
            self.queuedOutput.insert(o, at: 0)
        }
        upstream!.request(count: 1)
        update()
        return input.promise.future
    }

    /// Updates internal state.
    private func update() {
        while downstreamDemand > 0 {
            guard let output = queuedOutput.popLast() else {
                break
            }
            downstreamDemand -= 1
            downstream!.next(output)
        }
    }

    /// See `ConnectionContext.connection`
    public func connection(_ event: ConnectionEvent) {
        switch event {
        case .cancel: break // handle better
        case .request(let count):
            downstreamDemand += count
            update()
        }
    }

    /// See `InputStream.input`
    public func input(_ event: InputEvent<I>) {
        switch event {
        case .close: downstream?.close()
        case .connect(let upstream):
            self.upstream = upstream
            update()
        case .error(let error): downstream?.error(error)
        case .next(let input):
            var context: AsymmetricQueueStreamInput<Input>
            if let current = currentInput {
                context = current
            } else {
                let next = queuedInput.popLast()!
                currentInput = next
                context = next
            }

            do {
                if try context.onInput(input) {
                    currentInput = nil
                    context.promise.complete()
                } else {
                    upstream!.request(count: 1)
                }
            } catch {
                currentInput = nil
                context.promise.fail(error)
            }
        }
    }

    /// See `OutputStream.output`
    public func output<S>(to inputStream: S) where S : InputStream, S.Input == Output {
        downstream = .init(inputStream)
        inputStream.connect(to: self)
    }
}

final class AsymmetricQueueStreamInput<Input> {
    var promise: Promise<Void>
    var onInput: (Input) throws -> Bool

    init(onInput: @escaping (Input) throws -> Bool) {
        self.promise = .init()
        self.onInput = onInput
    }
}

infix operator !!
public func !!<T>(lhs: Optional<T>, rhs: String) -> T {
    switch lhs {
    case .none: fatalError(rhs)
    case .some(let w): return w
    }
}
