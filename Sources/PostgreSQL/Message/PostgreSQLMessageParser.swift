import Async
import Bits
import Foundation

/// Byte-stream parser for `PostgreSQLMessage`
final class PostgreSQLMessageParser: TranslatingStream {
    /// See `TranslatingStream.Input`
    typealias Input = ByteBuffer

    /// See `TranslatingStream.Output`
    typealias Output = PostgreSQLMessage

    /// Data being worked on currently.
    var buffered: Data

    /// Excess data waiting to be parsed.
    var excess: Data?

    /// Creates a new `PostgreSQLMessageParser`.
    init() {
        buffered = Data()
    }

    /// See TranslatingStream.translate
    func translate(input: ByteBuffer) throws -> Future<TranslatingStreamResult<PostgreSQLMessage>> {
        let result: TranslatingStreamResult<PostgreSQLMessage>
        if let excess = self.excess {
            self.excess = nil
            result = try parse(data: excess)
        } else {
            result = try parse(data: Data(input))
        }
        return Future(result)
    }

    /// Parses the data, setting `excess` or requesting more data if insufficient.
    func parse(data: Data) throws -> TranslatingStreamResult<PostgreSQLMessage> {
        let data = buffered + data
        guard let (message, remaining) = try PostgreSQLMessageDecoder().decode(data) else {
            buffered.append(data)
            return .insufficient
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
