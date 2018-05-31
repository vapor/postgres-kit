import Async
import Bits
import NIO
import Foundation

final class PostgreSQLMessageEncoder: MessageToByteEncoder {
    /// See `MessageToByteEncoder.OutboundIn`
    typealias OutboundIn = PostgreSQLMessage

    /// Called once there is data to encode. The used `ByteBuffer` is allocated by `allocateOutBuffer`.
    ///
    /// - parameters:
    ///     - ctx: The `ChannelHandlerContext` which this `ByteToMessageDecoder` belongs to.
    ///     - data: The data to encode into a `ByteBuffer`.
    ///     - out: The `ByteBuffer` into which we want to encode.
    func encode(ctx: ChannelHandlerContext, data message: PostgreSQLMessage, out buffer: inout ByteBuffer) throws {
        VERBOSE("PostgreSQLMessageSerializer.encode(ctx: \(ctx), data: \(message), out: \(buffer))")

        switch message {
        case .bind: buffer.write(integer: Byte.B)
        default: break // no identifier
        }
        
        // leave room for size
        let messageSizeIndex = buffer.writerIndex
        buffer.moveWriterIndex(forwardBy: 4)
        let messageStartIndex = buffer.writerIndex
        
        let identifier: Byte?
        switch message {
//        case .sslSupportRequest(let request):
//            identifier = nil
//            try request.encode(to: encoder)
//        case .startupMessage(let message):
//            identifier = nil
//            try message.encode(to: encoder)
//        case .query(let query):
//            identifier = .Q
//            try query.encode(to: encoder)
//        case .parse(let parseRequest):
//            identifier = .P
//            try parseRequest.encode(to: encoder)
//        case .sync:
//            identifier = .S
        case .bind(let bind): bind.serialize(into: &buffer)
//        case .describe(let describe):
//            identifier = .D
//            try describe.encode(to: encoder)
//        case .execute(let execute):
//            identifier = .E
//            try execute.encode(to: encoder)
//        case .password(let password):
//            identifier = .p
//            try password.encode(to: encoder)
        default: throw PostgreSQLError(identifier: "encoder", reason: "Unsupported encodable type: \(type(of: message))")
        }
        
        buffer.set(integer: Int32(buffer.writerIndex - messageStartIndex), at: messageSizeIndex)
    }
}
