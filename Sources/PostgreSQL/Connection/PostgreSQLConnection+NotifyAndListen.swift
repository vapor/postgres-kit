import Async

extension PostgreSQLConnection {
    public func listen(
        _ channelName: String,
        handler: @escaping (String) throws -> ()
        ) throws -> Future<Void> {
        beforeClose = { conn in
            let query = PostgreSQLQuery(query: "UNLISTEN \(channelName);")
            return conn.send([.query(query)], onResponse: { _ in })
        }
        let query = PostgreSQLQuery(query: "LISTEN \(channelName);")
        return queue.enqueue([.query(query)], onInput: { message in
            switch message {
            case let .notificationResponse(notification):
                try handler(notification.message)
                return true
            default:
                return false
            }
        })
    }

    public func notify(
        _ channelName: String, message: String) throws -> Future<Void> {
        let query = PostgreSQLQuery(query: "NOTIFY \(channelName), '\(message)';")
        return send([.query(query)]).map(to: Void.self, { _ in })
    }
}
