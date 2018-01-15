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
        return queueStream.enqueue(message) { message in
            switch message {
            case .readyForQuery: return true
            case .errorResponse(let e): throw e
            default: return false
            }
        }
    }

    /// Sends a simple PostgreSQL query command, returning the parsed results.
    func query(_ string: String) -> Future<[[String: PostgreSQLData]]> {
        let query = PostgreSQLQuery(query: string)
        return send(.query(query)).map(to: [[String: PostgreSQLData]].self) { queryOutput in
            var results: [[String: PostgreSQLData]] = []
            var currentRow: PostgreSQLRowDescription?

            for message in queryOutput {
                switch message {
                case .rowDescription(let row):
                    currentRow = row
                case .dataRow(let data):
                    guard let row = currentRow else {
                        fatalError("Unexpected PostgreSQLDataRow without preceding PostgreSQLRowDescription.")
                    }

                    var parsed: [String: PostgreSQLData] = [:]

                    // iterate over the fields, parsing values
                    // based on column type
                    for (i, field) in row.fields.enumerated() {
                        let col = data.columns[i]
                        let data: PostgreSQLData
                        switch field.formatCode {
                        case .text:
                            switch field.dataType {
                            case .bool:
                                data = try col.makeString().flatMap { $0 == "t" }.flatMap { .bool($0) } ?? .null
                            case .text, .name:
                                data = try col.makeString().flatMap { .string($0) } ?? .null
                            case .oid, .regproc, .int4:
                                data = try col.makeString().flatMap { Int32($0) }.flatMap { .int32($0) } ?? .null
                            case .int2:
                                data = try col.makeString().flatMap { Int16($0) }.flatMap { .int16($0) } ?? .null
                            case .char:
                                data = try col.makeString().flatMap { Character($0) }.flatMap { .character($0) } ?? .null
                            case .pg_node_tree:
                                print("\(field.name): is pg node tree")
                                data = .null
                            case ._aclitem:
                                print("\(field.name): is acl item")
                                data = .null
                            }
                        case .binary: fatalError("Binary format code not supported.")
                        }

                        parsed[field.name] = data
                    }

                    // append the result
                    results.append(parsed)
                default: break
                }
            }
            return results
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
    public func enqueue(_ output: Output, readyCheck: @escaping (Input) throws -> Bool) -> Future<[Input]> {
        let input = AsymmetricQueueStreamInput(readyCheck: readyCheck)
        self.queuedInput.insert(input, at: 0)
        self.queuedOutput.insert(output, at: 0)
        upstream!.request()
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

            context.storage.append(input)
            do {
                if try context.readyCheck(input) {
                    context.promise.complete(context.storage)
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
    var storage: [Input]
    var promise: Promise<[Input]>
    var readyCheck: (Input) throws -> Bool

    init(readyCheck: @escaping (Input) throws -> Bool) {
        self.storage = []
        self.promise = .init()
        self.readyCheck = readyCheck
    }
}
