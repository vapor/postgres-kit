//extension PostgreSQLConnection {
//    /// Note: after calling `listen'` on a connection, it can no longer handle other database operations. Do not try to send other SQL commands through this connection afterwards.
//    /// IAlso, notifications will only be sent for as long as this connection remains open; you are responsible for opening a new connection to listen on when this one closes.
//    internal func listen(_ channelName: String, handler: @escaping (String) throws -> ()) throws -> Future<Void> {
//        closeHandlers.append({ conn in
//            let query = PostgreSQLQuery(query: "UNLISTEN \"\(channelName)\";")
//            return conn.send([.query(query)], onResponse: { _ in })
//        })
//
//        notificationHandlers[channelName] = { message in
//            try handler(message)
//        }
//        let query = PostgreSQLQuery(query: "LISTEN \"\(channelName)\";")
//        return queue.enqueue([.query(query)], onInput: { message in
//            switch message {
//            case let .notificationResponse(notification):
//                try self.notificationHandlers[notification.channel]?(notification.message)
//            default:
//                break
//            }
//            return false
//        })
//    }
//
//    internal func notify(_ channelName: String, message: String) throws -> Future<Void> {
//        let query = PostgreSQLQuery(query: "NOTIFY \"\(channelName)\", '\(message)';")
//        return send([.query(query)]).map(to: Void.self, { _ in })
//    }
//
//    internal func unlisten(_ channelName: String, unlistenHandler: (() -> Void)? = nil) throws -> Future<Void> {
//        notificationHandlers.removeValue(forKey: channelName)
//        let query = PostgreSQLQuery(query: "UNLISTEN \"\(channelName)\";")
//        return send([.query(query)], onResponse: { _ in unlistenHandler?() })
//    }
//}
