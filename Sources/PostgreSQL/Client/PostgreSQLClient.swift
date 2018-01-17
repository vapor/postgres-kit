import Async

/// A PostgreSQL frontend client.
final class PostgreSQLClient {
    /// Handles enqueued redis commands and responses.
    private let queueStream: AsymmetricQueueStream<PostgreSQLMessage, PostgreSQLMessage>

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
    func send(_ message: PostgreSQLMessage) -> Future<[PostgreSQLMessage]> {
        var responses: [PostgreSQLMessage] = []
        return queueStream.enqueue([message]) { message in
            responses.append(message)
            switch message {
            case .readyForQuery: return true
            case .errorResponse(let e): throw e
            default: return false
            }
        }.map(to: [PostgreSQLMessage].self) {
            return responses
        }
    }

    /// Sends a simple PostgreSQL query command, collecting the parsed results.
    func query(_ string: String) -> Future<[[String: PostgreSQLData]]> {
        var rows: [[String: PostgreSQLData]] = []
        return query(string) { row in
            rows.append(row)
            }.map(to: [[String: PostgreSQLData]].self) {
                return rows
        }
    }

    /// Sends a simple PostgreSQL query command, returning the parsed results to
    /// the supplied closure.
    func query(_ string: String, onRow: @escaping ([String: PostgreSQLData]) -> ()) -> Future<Void> {
        var currentRow: PostgreSQLRowDescription?
        let query = PostgreSQLQuery(query: string)
        return queueStream.enqueue([.query(query)]) { message in
            switch message {
            case .rowDescription(let row):
                currentRow = row
            case .dataRow(let data):
                let row = currentRow !! "Unexpected PostgreSQLDataRow without preceding PostgreSQLRowDescription."
                let parsed = try row.parse(data: data)
                onRow(parsed)
            case .close: break // query over, waiting for `readyForQuery`
            case .readyForQuery: return true
            case .errorResponse(let e): throw e
            default: fatalError("Unexpected message during PostgreSQLQuery: \(message)")
            }
            return false // more messages, please
        }
    }

    /// Sends a parameterized PostgreSQL query command, collecting the parsed results.
    func parameterizedQuery(
        _ string: String,
        _ parameters: [PostgreSQLData] = []
    ) throws -> Future<[[String: PostgreSQLData]]> {
        var rows: [[String: PostgreSQLData]] = []
        return try parameterizedQuery(string, parameters) { row in
            rows.append(row)
        }.map(to: [[String: PostgreSQLData]].self) {
            return rows
        }
    }

    /// Sends a parameterized PostgreSQL query command, returning the parsed results to
    /// the supplied closure.
    func parameterizedQuery(
        _ string: String,
        _ parameters: [PostgreSQLData] = [],
        onRow: @escaping ([String: PostgreSQLData]) -> ()
    ) throws -> Future<Void> {
        let parse = PostgreSQLParseRequest(
            statementName: "",
            query: string,
            parameterTypes: parameters.map { .type(forData: $0) }
        )
        let bind = try PostgreSQLBindRequest(
            portalName: "",
            statementName: "",
            parameterFormatCodes: [.binary],
            parameters: parameters.map { try .serialize(data: $0) },
            resultFormatCodes: [.binary]
        )
        let describe = PostgreSQLDescribeRequest(type: .portal, name: "")
        let execute = PostgreSQLExecuteRequest(
            portalName: "",
            maxRows: 0
        )
        var currentRow: PostgreSQLRowDescription?
        return queueStream.enqueue([
            .parse(parse), .bind(bind), .describe(describe), .execute(execute), .sync
        ]) { message in
            switch message {
            case .errorResponse(let e): throw e
            case .parseComplete: return false
            case .bindComplete: return false
            case .rowDescription(let row):
                currentRow = row
                return false
            case .dataRow(let data):
                let row = currentRow !! "Unexpected PostgreSQLDataRow without preceding PostgreSQLRowDescription."
                let parsed = try row.parse(data: data)
                onRow(parsed)
                return false
            case .close: return false
            case .readyForQuery: return true
            default: fatalError("Unexpected message during PostgreSQLParseRequest: \(message)")
            }
        }
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
                    context.promise.complete()
                    currentInput = nil
                } else {
                    upstream!.request(count: 1)
                }
            } catch {
                context.promise.fail(error)
                currentInput = nil
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
