import Async
import Bits
import Foundation

final class PostgreSQLMessageParser: TranslatingStream {
    typealias Input = ByteBuffer
    typealias Output = PostgreSQLMessage

    var buffered: Data
    var excess: Data?

    init() {
        buffered = Data()
    }

    func translate(input: ByteBuffer) throws -> Future<TranslatingStreamResult<PostgreSQLMessage>> {
        return try Future(_translate(input: input))
    }

    func _translate(input: ByteBuffer) throws -> TranslatingStreamResult<PostgreSQLMessage> {
        if let excess = self.excess {
            return try parse(data: excess)
        } else {
            return try parse(data: Data(input))
        }
    }

    func parse(data: Data) throws -> TranslatingStreamResult<PostgreSQLMessage> {
        // print("Parse: \(data.hexDebug)")
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
