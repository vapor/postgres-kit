import Async
import Bits
import Foundation

/// Byte-stream parser for `PostgreSQLMessage`
final class PostgreSQLMessageParser: TranslatingStream {
    /// Data being worked on currently.
    var buffered: Data

    /// Excess data waiting to be parsed.
    var excess: Data?

    /// Creates a new `PostgreSQLMessageParser`.
    init() {
        buffered = Data()
    }

    /// See TranslatingStream.translate
    func translate(input context: inout TranslatingStreamInput<ByteBuffer>) throws -> TranslatingStreamOutput<PostgreSQLMessage> {
        if let excess = self.excess {
            self.excess = nil
            return try parse(data: excess)
        } else {
            guard let input = context.input else {
                return .insufficient()
            }
            return try parse(data: Data(input))
        }
    }

    /// Parses the data, setting `excess` or requesting more data if insufficient.
    func parse(data: Data) throws -> TranslatingStreamOutput<PostgreSQLMessage> {
        let data = buffered + data
        guard let (message, remaining) = try PostgreSQLMessageDecoder().decode(data) else {
            buffered.append(data)
            return .insufficient()
        }

        buffered = .init()
        if remaining > 0 {
            let start = data.count - remaining
            excess = data[start..<data.count]
            return .excess(message)
        }  else {
            return .sufficient(message)
        }
    }
}
