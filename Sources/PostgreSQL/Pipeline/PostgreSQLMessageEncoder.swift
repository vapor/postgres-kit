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
        case .bind: buffer.write(integer: .B, as: Byte.self)
        case .describe: buffer.write(integer: .D, as: Byte.self)
        case .execute: buffer.write(integer: .E, as: Byte.self)
        case .parse: buffer.write(integer: .P, as: Byte.self)
        case .password: buffer.write(integer: .p, as: Byte.self)
        case .query: buffer.write(integer: .Q, as: Byte.self)
        case .sync: buffer.write(integer: .S, as: Byte.self)
        default: break // no identifier
        }
        
        // leave room for size
        let messageSizeIndex = buffer.writerIndex
        buffer.moveWriterIndex(forwardBy: 4)
        
        switch message {
        case .bind(let bind): bind.serialize(into: &buffer)
        case .describe(let describe): describe.serialize(into: &buffer)
        case .execute(let execute): execute.serialize(into: &buffer)
        case .parse(let parse): parse.serialize(into: &buffer)
        case .password(let password): password.serialize(into: &buffer)
        case .query(let query): query.serialize(into: &buffer)
        case .sslSupportRequest(let request): buffer.write(integer: request.code)
        case .startupMessage(let message): message.serialize(into: &buffer)
        case .sync: break
        default:
            throw PostgreSQLError(identifier: "encoder", reason: "Unsupported encodable type: \(type(of: message))")
        }
        buffer.set(integer: Int32(buffer.writerIndex - messageSizeIndex), at: messageSizeIndex)
    }
}
