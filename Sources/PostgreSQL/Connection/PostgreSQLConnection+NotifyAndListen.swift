import Async

extension PostgreSQLConnection {
    /// Note: after calling `listen'` on a connection, it can no longer handle other database operations. Do not try to send other SQL commands through this connection afterwards.
    /// IAlso, notifications will only be sent for as long as this connection remains open; you are responsible for opening a new connection to listen on when this one closes.
    public func listen(
        _ channelName: String,
        handler: @escaping (String) throws -> ()
        ) throws -> Future<Void> {
        beforeClose = { conn in
            let query = PostgreSQLQuery(query: "UNLISTEN \"\(channelName)\";")
            return conn.send([.query(query)], onResponse: { _ in })
        }
        let query = PostgreSQLQuery(query: "LISTEN \"\(channelName)\";")
        return queue.enqueue([.query(query)], onInput: { message in
            switch message {
            case let .notificationResponse(notification):
                try handler(notification.message)
            default:
                break
            }
            return false
        })
    }

    public func notify(
        _ channelName: String, message: String) throws -> Future<Void> {
        let query = PostgreSQLQuery(query: "NOTIFY \"\(channelName)\", '\(message)';")
        return send([.query(query)]).map(to: Void.self, { _ in })
    }
}
