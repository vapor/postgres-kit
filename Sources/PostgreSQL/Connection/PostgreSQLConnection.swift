import Async
import Crypto

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
        var responses: [PostgreSQLMessage] = []
        return send(message) { response in
            responses.append(response)
        }.map(to: [PostgreSQLMessage].self) {
            return responses
        }
    }

    /// Authenticates the `PostgreSQLClient` using a username with no password.
    public func authenticate(username: String, database: String? = nil, password: String? = nil) -> Future<Void> {
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

            let input: [PostgreSQLMessage]
            switch auth {
            case .ok:
                guard password == nil else {
                    throw PostgreSQLError(identifier: "trust", reason: "No password is required")
                }
                input = []
            case .plaintext:
                guard let password = password else {
                    throw PostgreSQLError(identifier: "password", reason: "Password is required")
                }
                let passwordMessage = PostgreSQLPasswordMessage(password: password)
                input = [.password(passwordMessage)]
            case .md5(let salt):
                guard let password = password else {
                    throw PostgreSQLError(identifier: "password", reason: "Password is required")
                }
                guard let passwordData = password.data(using: .utf8) else {
                    throw PostgreSQLError(identifier: "passwordUTF8", reason: "Could not convert password to UTF-8 encoded Data.")
                }

                guard let usernameData = username.data(using: .utf8) else {
                    throw PostgreSQLError(identifier: "usernameUTF8", reason: "Could not convert username to UTF-8 encoded Data.")
                }

                let hasher = MD5()
                // pwdhash = md5(password + username).hexdigest()
                var passwordUsernameData = passwordData + usernameData
                hasher.update(sequence: &passwordUsernameData)
                hasher.finalize()
                guard let pwdhash = hasher.hash.hexString.data(using: .utf8) else {
                    throw PostgreSQLError(identifier: "hashUTF8", reason: "Could not convert password hash to UTF-8 encoded Data.")
                }
                hasher.reset()
                // hash = ′ md 5′ + md 5(pwdhash + salt ).hexdigest ()
                var saltedData = pwdhash + salt
                hasher.update(sequence: &saltedData)
                hasher.finalize()
                let passwordMessage = PostgreSQLPasswordMessage(password: "md5" + hasher.hash.hexString)
                input = [.password(passwordMessage)]
            }

            return self.queueStream.enqueue(input) { message in
                switch message {
                case .error(let error): throw error
                case .readyForQuery: return true
                case .authenticationRequest: return false
                case .parameterStatus, .backendKeyData: return false
                default: throw PostgreSQLError(identifier: "authenticationMessage", reason: "Unexpected authentication message: \(message)")
                }
            }
        }
    }

    /// Closes this client.
    public func close() {
        queueStream.close()
    }
}
