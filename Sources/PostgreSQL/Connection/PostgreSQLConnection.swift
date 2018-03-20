import Async
import Crypto
import NIO

/// A PostgreSQL frontend client.
public final class PostgreSQLConnection {
    public var eventLoop: EventLoop {
        return channel.eventLoop
    }

    /// Handles enqueued PostgreSQL commands and responses.
    private let queue: QueueHandler<PostgreSQLMessage, PostgreSQLMessage>

    /// The channel
    private let channel: Channel

    /// If non-nil, will log queries.
    public var logger: PostgreSQLLogger?

    /// Caches oid -> table name data.
    internal weak var tableNameCache: PostgreSQLTableNameCache?

    /// Creates a new PostgreSQL client on the provided data source and sink.
    init(queue: QueueHandler<PostgreSQLMessage, PostgreSQLMessage>, channel: Channel) {
        self.queue = queue
        self.channel = channel
    }

    /// Sends `PostgreSQLMessage` to the server.
    func send(_ messages: [PostgreSQLMessage], onResponse: @escaping (PostgreSQLMessage) throws -> ()) -> Future<Void> {
        var error: Error?
        return queue.enqueue(messages) { message in
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
        return queue.enqueue([.startupMessage(startup)]) { message in
            switch message {
            case .authenticationRequest(let a):
                authRequest = a
                return true
            default: throw PostgreSQLError(identifier: "auth", reason: "Unsupported message encountered during auth: \(message).", source: .capture())
            }
        }.flatMap(to: Void.self) {
            guard let auth = authRequest else {
                throw PostgreSQLError(identifier: "authRequest", reason: "No authorization request / status sent.", source: .capture())
            }

            let input: [PostgreSQLMessage]
            switch auth {
            case .ok:
                guard password == nil else {
                    throw PostgreSQLError(identifier: "trust", reason: "No password is required", source: .capture())
                }
                input = []
            case .plaintext:
                guard let password = password else {
                    throw PostgreSQLError(identifier: "password", reason: "Password is required", source: .capture())
                }
                let passwordMessage = PostgreSQLPasswordMessage(password: password)
                input = [.password(passwordMessage)]
            case .md5(let salt):
                guard let password = password else {
                    throw PostgreSQLError(identifier: "password", reason: "Password is required", source: .capture())
                }
                guard let passwordData = password.data(using: .utf8) else {
                    throw PostgreSQLError(identifier: "passwordUTF8", reason: "Could not convert password to UTF-8 encoded Data.", source: .capture())
                }

                guard let usernameData = username.data(using: .utf8) else {
                    throw PostgreSQLError(identifier: "usernameUTF8", reason: "Could not convert username to UTF-8 encoded Data.", source: .capture())
                }

                let hasher = MD5()
                // pwdhash = md5(password + username).hexdigest()
                var passwordUsernameData = passwordData + usernameData
                hasher.update(sequence: &passwordUsernameData)
                hasher.finalize()
                guard let pwdhash = hasher.hash.hexString.data(using: .utf8) else {
                    throw PostgreSQLError(identifier: "hashUTF8", reason: "Could not convert password hash to UTF-8 encoded Data.", source: .capture())
                }
                hasher.reset()
                // hash = ′ md 5′ + md 5(pwdhash + salt ).hexdigest ()
                var saltedData = pwdhash + salt
                hasher.update(sequence: &saltedData)
                hasher.finalize()
                let passwordMessage = PostgreSQLPasswordMessage(password: "md5" + hasher.hash.hexString)
                input = [.password(passwordMessage)]
            }

            return self.queue.enqueue(input) { message in
                switch message {
                case .error(let error): throw error
                case .readyForQuery: return true
                case .authenticationRequest: return false
                case .parameterStatus, .backendKeyData: return false
                default: throw PostgreSQLError(identifier: "authenticationMessage", reason: "Unexpected authentication message: \(message)", source: .capture())
                }
            }
        }
    }

    /// Closes this client.
    public func close() {
        channel.close(promise: nil)
    }
}
