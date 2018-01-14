import Async
import Bits
import Foundation

final class PostgreSQLMessageSerializer: ByteSerializer {
    typealias Input = PostgreSQLMessage
    typealias Output = ByteBuffer

    var state: ByteSerializerState<PostgreSQLMessageSerializer>
    let buffer: MutableByteBuffer

    init(bufferSize: Int = 4096) {
        buffer = MutableByteBuffer(start: .allocate(capacity: bufferSize), count: bufferSize)
        state = .init()
    }

    func serialize(_ message: PostgreSQLMessage, state: Data?) throws -> ByteSerializerResult<PostgreSQLMessageSerializer> {
        if let state = state {
            return serialize(data: state)
        }

        let data = try PostgreSQLMessageEncoder().encode(message)
        return serialize(data: data)
    }

    func serialize(data: Data) -> ByteSerializerResult<PostgreSQLMessageSerializer> {
        print("serialize: \(data.hexDebug)")
        let count = data.copyBytes(to: buffer)
        let view = ByteBuffer(start: buffer.baseAddress, count: count)
        if data.count > count {
            return .incomplete(view, state: data[count..<data.count])
        } else {
            return .complete(view)
        }
    }

    deinit {
        buffer.baseAddress?.deallocate(capacity: buffer.count)
    }
}
