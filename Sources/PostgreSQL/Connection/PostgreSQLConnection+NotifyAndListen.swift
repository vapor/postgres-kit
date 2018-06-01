extension PostgreSQLConnection {
    internal func listen(_ channelName: String, handler: @escaping (String) throws -> ()) throws -> Future<Void> {
        closeHandlers.append({ conn in
            return conn.send([.query(.init(query: "UNLISTEN \"\(channelName)\";"))], onResponse: { _ in })
        })

        notificationHandlers[channelName] = { message in
            try handler(message)
        }
        return queue.enqueue([.query(.init(query: "LISTEN \"\(channelName)\";"))], onInput: { message in
            switch message {
            case let .notificationResponse(notification):
                try self.notificationHandlers[notification.channel]?(notification.message)
            default:
                break
            }
            return false
        })
    }

    internal func notify(_ channelName: String, message: String) throws -> Future<Void> {
        return send([.query(.init(query: "NOTIFY \"\(channelName)\", '\(message)';"))]).map(to: Void.self, { _ in })
    }

    internal func unlisten(_ channelName: String, unlistenHandler: (() -> Void)? = nil) throws -> Future<Void> {
        notificationHandlers.removeValue(forKey: channelName)
        return send([.query(.init(query: "UNLISTEN \"\(channelName)\";"))], onResponse: { _ in unlistenHandler?() })
    }
}
