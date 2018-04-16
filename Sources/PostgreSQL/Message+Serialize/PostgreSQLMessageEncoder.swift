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
    func encode(ctx: ChannelHandlerContext, data message: PostgreSQLMessage, out: inout ByteBuffer) throws {
        VERBOSE("PostgreSQLMessageSerializer.encode(ctx: \(ctx), data: \(message), out: \(out))")

        let encoder = _PostgreSQLMessageEncoder()
        let identifier: Byte?
        switch message {
        case .sslMessage(let message):
            identifier = nil
            try message.encode(to: encoder)
        case .startupMessage(let message):
            identifier = nil
            try message.encode(to: encoder)
        case .query(let query):
            identifier = .Q
            try query.encode(to: encoder)
        case .parse(let parseRequest):
            identifier = .P
            try parseRequest.encode(to: encoder)
        case .sync:
            identifier = .S
        case .bind(let bind):
            identifier = .B
            try bind.encode(to: encoder)
        case .describe(let describe):
            identifier = .D
            try describe.encode(to: encoder)
        case .execute(let execute):
            identifier = .E
            try execute.encode(to: encoder)
        case .password(let password):
            identifier = .p
            try password.encode(to: encoder)
        default: throw PostgreSQLError(identifier: "encoder", reason: "Unsupported encodable type: \(type(of: message))", source: .capture())
        }
        encoder.updateSize()

        let data: Data
        if let prefix = identifier {
            data = [prefix] + encoder.data
        } else {
            data = encoder.data
        }

        out.write(bytes: data)
        VERBOSE("    [bytes=\(data.hexDebug)]")
        VERBOSE("    [out=\(data.debugDescription)]")
    }
}
