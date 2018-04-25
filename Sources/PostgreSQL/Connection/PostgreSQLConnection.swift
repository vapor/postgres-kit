import Async
import Crypto
import NIO

/// A PostgreSQL frontend client.
public final class PostgreSQLConnection {
    public var eventLoop: EventLoop {
        return channel.eventLoop
    }

    /// Handles enqueued redis commands and responses.
    internal let queue: QueueHandler<PostgreSQLMessage, PostgreSQLMessage>

    /// The channel
    private let channel: Channel

    /// If non-nil, will log queries.
    public var logger: PostgreSQLLogger?

    /// Returns a new unique portal name.
    internal var nextPortalName: String {
        defer { uniqueNameCounter = uniqueNameCounter &+ 1 }
        return "p_\(uniqueNameCounter)"
    }

    /// Returns a new unique statement name.
    internal var nextStatementName: String {
        defer { uniqueNameCounter = uniqueNameCounter &+ 1 }
        return "s_\(uniqueNameCounter)"
    }

    /// A unique identifier for this connection, used to generate statment and portal names
    private var uniqueNameCounter: UInt8

    /// Creates a new Redis client on the provided data source and sink.
    init(queue: QueueHandler<PostgreSQLMessage, PostgreSQLMessage>, channel: Channel) {
        self.queue = queue
        self.channel = channel
        self.uniqueNameCounter = 0
    }
    
    deinit {
        close()
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

                // pwdhash = md5(password + username).hexdigest()
                let pwdhash = try MD5.hash(passwordData + usernameData).hexEncodedString()
                // hash = "md5" + md 5(pwdhash + salt).hexdigest()
                let hash = try "md5" + MD5.hash(Data(pwdhash.utf8) + salt).hexEncodedString()

                let passwordMessage = PostgreSQLPasswordMessage(password: hash)
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

    internal var beforeClose: ((PostgreSQLConnection) -> Future<Void>)?

    /// Closes this client.
    public func close() {
        if let beforeClose = beforeClose {
            _ = beforeClose(self).then { _ in
                self.channel.close(mode: CloseMode.all)
            }
        } else {
            channel.close(promise: nil)
        }
    }
}
