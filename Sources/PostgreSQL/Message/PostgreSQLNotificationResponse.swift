import Foundation

struct PostgreSQLNotificationResponse: Decodable {
    /// The message coming from PSQL
    let message: String
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        _ = try container.decode(Int32.self) // message length
        _ = try container.decode(Int32.self) // process id of message
        let channelId = try container.decode(String.self)
        let message = try? container.decode(String.self)
        self.message = message ?? channelId
    }
}
