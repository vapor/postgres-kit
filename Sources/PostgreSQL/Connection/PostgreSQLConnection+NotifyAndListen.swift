extension PostgreSQLConnection {
    /// Begins listening for notifications on a channel.
    ///
    ///     LISTEN "<channel name>"
    ///
    /// To subscribe to a channel, call `listen(...)` and provide the channel name.
    ///
    ///     conn.listen("foo") { message in
    ///         print(message)
    ///         return true
    ///     }
    ///
    /// Once a connection is listening, it may not be used to send further queries until `UNLISTEN` is sent.
    /// To unlisten, return `true` in the callback handler. Returning `false` will continue the subscription.
    ///
    /// See `notify(...)` to send messages.
    ///
    /// - parameters:
    ///     - channelName: String identifier for the channel to subscribe to.
    ///     - handler: Handles incoming String messages. Returning `true` here will end the subscription
    ///                sending an `UNLISTEN` command.
    /// - returns: A future that signals completion of the `UNLISTEN` command.
    public func listen(_ channel: String, handler: @escaping (String) throws -> (Bool)) -> Future<Void> {
        let promise = eventLoop.newPromise(Void.self)
        return queue.enqueue([.query(.init(query: "LISTEN \"\(channel)\";"))]) { message in
            switch message {
            case .close: return false
            case .readyForQuery: return false
            case .notification(let notif):
                if try handler(notif.message) {
                    self.simpleQuery("UNLISTEN \"\(channel)\"").cascade(promise: promise)
                    return true
                } else {
                    return false
                }
            default: throw PostgreSQLError(identifier: "listen", reason: "Unexpected message during listen: \(message).")
            }
        }.flatMap { promise.futureResult }
    }

    /// Sends a notification to a listening connection. Use in conjunction with `listen(...)`.
    ///
    ///     NOTIFY "foo" 'hello'
    ///
    /// A single connection can be used to send notifications to as many channels as desired.
    ///
    ///     conn.notify("foo", message: "hello")
    ///
    /// - parameters:
    ///     - channelName: String identifier for the channel to send to.
    ///     - message: String message to send to subscribers.
    /// - returns: A future that signals completion of the send.
    public func notify(_ channel: String, message: String) -> Future<Void> {
        return simpleQuery("NOTIFY \"\(channel)\", '\(message)'")
    }
}

