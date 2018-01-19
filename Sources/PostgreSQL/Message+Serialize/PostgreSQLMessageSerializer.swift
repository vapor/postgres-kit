import Async
import Bits
import Foundation

/// Byte-stream serializer for `PostgreSQLMessage`.
final class PostgreSQLMessageSerializer: TranslatingStream {
    /// See `TranslatingStream.Input`
    typealias Input = PostgreSQLMessage

    /// See `TranslatingStream.Output`
    typealias Output = ByteBuffer

    /// The internal buffer to serialize messages into.
    let buffer: MutableByteBuffer

    /// Excess data from a previous serialization that needs to be processed.
    var excess: Data?

    /// Creates a new `PostgreSQLMessageSerializer`.
    init(bufferSize: Int = 4096) {
        buffer = MutableByteBuffer(start: .allocate(capacity: bufferSize), count: bufferSize)
    }

    /// See `TranslatingStream.translate`
    func translate(input context: inout TranslatingStreamInput<PostgreSQLMessage>) throws -> TranslatingStreamOutput<ByteBuffer> {
        if let excess = self.excess {
            self.excess = nil
            return serialize(data: excess)
        } else {
            guard let input = context.input else {
                return .insufficient()
            }
            let data = try PostgreSQLMessageEncoder().encode(input)
            return serialize(data: data)
        }
    }

    /// Serializes data, storing `excess` if it does not fit in the buffer.
    func serialize(data: Data) -> TranslatingStreamOutput<ByteBuffer> {
        let count = data.copyBytes(to: buffer)
        let view = ByteBuffer(start: buffer.baseAddress, count: count)
        if data.count > count {
            self.excess = data[count..<data.count]
            return .excess(view)
        } else {
            return .sufficient(view)
        }
    }

    /// Called when `PostgreSQLMessageSerializer` deinitializes.
    deinit {
        buffer.baseAddress?.deallocate(capacity: buffer.count)
    }
}
