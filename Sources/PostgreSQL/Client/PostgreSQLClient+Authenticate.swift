import Async

extension PostgreSQLClient {
    /// Authenticates the `PostgreSQLClient` using a username with no password.
    public func authenticate(username: String) -> Future<Void> {
        let startup = PostgreSQLStartupMessage.versionThree(parameters: ["user": username])
        return send([.startupMessage(startup)]).transform(to: ())
    }
}
