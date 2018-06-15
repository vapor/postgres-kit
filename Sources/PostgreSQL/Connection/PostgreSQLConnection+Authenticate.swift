import Crypto

extension PostgreSQLConnection {
    /// Authenticates the `PostgreSQLClient` using a username with no password.
    public func authenticate(username: String, database: String? = nil, password: String? = nil) -> Future<Void> {
        var authRequest: PostgreSQLMessage.AuthenticationRequest?
        return queue.enqueue([.startupMessage(.versionThree(parameters: [
            "user": username,
            "database": database ?? username
        ]))]) { message in
            switch message {
            case .authenticationRequest(let a):
                authRequest = a
                return true
            case .error(let error): throw PostgreSQLError.errorResponse(error)
            default: throw PostgreSQLError(identifier: "auth", reason: "Unsupported message encountered during auth: \(message).")
            }
        }.flatMap {
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
                input = [.password(.init(password: password))]
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
                
                // pwdhash = md5(password + username).hexdigest()
                let pwdhash = try MD5.hash(passwordData + usernameData).hexEncodedString()
                // hash = "md5" + md 5(pwdhash + salt).hexdigest()
                let hash = try "md5" + MD5.hash(Data(pwdhash.utf8) + salt).hexEncodedString()
                input = [.password(.init(password: hash))]
            }
            
            return self.queue.enqueue(input) { message in
                switch message {
                case .error(let error): throw PostgreSQLError.errorResponse(error)
                case .readyForQuery: return true
                case .authenticationRequest: return false
                case .parameterStatus, .backendKeyData: return false
                default: throw PostgreSQLError(identifier: "authenticationMessage", reason: "Unexpected authentication message: \(message)")
                }
            }
        }
    }
}
