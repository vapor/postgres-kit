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
        var error: Error?
        return queueStream.enqueue(messages) { message in
            switch message {
            case .readyForQuery:
                if let e = error { throw e }
                return true
            case .error(let e): error = e
            case .notice(let n): print(n)
            default: try onResponse(message)
            }
            return false // request until ready for query
        }
    }

    /// Sends `PostgreSQLMessage` to the server.
    func send(_ message: [PostgreSQLMessage]) -> Future<[PostgreSQLMessage]> {
        print(message)
        var responses: [PostgreSQLMessage] = []
        return send(message) { response in
            print(response)
            responses.append(response)
        }.map(to: [PostgreSQLMessage].self) {
            return responses
        }
    }

    /// Authenticates the `PostgreSQLClient` using a username with no password.
    public func authenticate(username: String, database: String? = nil) -> Future<Void> {
        let startup = PostgreSQLStartupMessage.versionThree(parameters: [
            "user": username,
            "database": database ?? username
        ])
        var authRequest: PostgreSQLAuthenticationRequest?
        return queueStream.enqueue([.startupMessage(startup)]) { message in
            switch message {
            case .authenticationRequest(let a):
                authRequest = a
                return true
            default: throw PostgreSQLError(identifier: "auth", reason: "Unsupported message encountered during auth: \(message).")
            }
        }.flatMap(to: Void.self) {
            guard let auth = authRequest else {
                throw PostgreSQLError(identifier: "authRequest", reason: "No authorization request / status sent.")
            }

            switch auth {
            case .ok: return .done
            case .plaintext: throw PostgreSQLError(identifier: "plaintext", reason: "Plaintext password not supported. Use MD5.")
            case .md5(let salt):
                /// FIXME: hash password
                let password = PostgreSQLPasswordMessage(password: "123")
                return self.queueStream.enqueue([.password(password)]) { message in
                    switch message {
                    case .error(let error):
                        throw error
                    default: return true
                    }
                }
            }
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
