//import Async
//import Bits
//import Foundation
//
//struct PostgresSerializerState {
//    var remaining: Data
//}
//
//final class PostgresSerializer: ByteSerializer {
//    var state: ByteSerializerState<PostgresSerializer>
//
//    typealias Input = PostgresMessage
//    typealias Output = ByteBuffer
//
//    let buffer: MutableByteBuffer
//
//    init() {
//        buffer = MutableByteBuffer(start: .allocate(capacity: 4096), count: 4096)
//        state = .init()
//    }
//
//    func serialize(
//        _ message: PostgresMessage,
//        state: PostgresSerializerState?
//    ) throws -> ByteSerializerResult<PostgresSerializer> {
//        if let state = state {
//            return serialize(data: state.remaining)
//        }
//
//        switch message {
//        case .startupMessage(let protocolVersion, let parameters):
//            var data = Data([0, 0, 0, 0])
//            for word in protocolVersion.words {
//                data.append(Byte(word))
//            }
//            for (key, val) in parameters {
//                data.append(contentsOf: key.data(using: .ascii)!)
//                data.append(contentsOf: [0])
//                data.append(contentsOf: val.data(using: .ascii)!)
//                data.append(contentsOf: [0])
//            }
//            data.append(contentsOf: [0])
//            return serialize(data: data)
//        }
//    }
//
//    func serialize(data: Data) -> ByteSerializerResult<PostgresSerializer> {
//        let count = data.copyBytes(to: buffer)
//        let view = ByteBuffer(start: buffer.baseAddress, count: count)
//        if data.count > count {
//            return .incomplete(view, state: .init(remaining: data[count..<data.count]))
//        } else {
//            return .complete(view)
//        }
//    }
//
//    deinit {
//        buffer.baseAddress?.deallocate(capacity: buffer.count)
//    }
//}

