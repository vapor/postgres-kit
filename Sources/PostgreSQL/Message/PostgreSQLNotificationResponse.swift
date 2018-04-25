import Foundation

struct PostgreSQLNotificationResponse: Decodable {
    /// The message coming from PSQL
    let channel: String
    let message: String
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        _ = try container.decode(Int32.self)
        channel = try container.decode(String.self)
        message = try container.decode(String.self)
    }
}
