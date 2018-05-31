import Async
import Bits
import NIO

final class PostgreSQLMessageDecoder: ByteToMessageDecoder {
    /// See `ByteToMessageDecoder.InboundOut`
    public typealias InboundOut = PostgreSQLMessage

    /// The cumulationBuffer which will be used to buffer any data.
    var cumulationBuffer: ByteBuffer?

    /// Decode from a `ByteBuffer`. This method will be called till either the input
    /// `ByteBuffer` has nothing to read left or `DecodingState.needMoreData` is returned.
    ///
    /// - parameters:
    ///     - ctx: The `ChannelHandlerContext` which this `ByteToMessageDecoder` belongs to.
    ///     - buffer: The `ByteBuffer` from which we decode.
    /// - returns: `DecodingState.continue` if we should continue calling this method or `DecodingState.needMoreData` if it should be called
    //             again once more data is present in the `ByteBuffer`.
    func decode(ctx: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        VERBOSE("PostgreSQLMessageDecoder.decode(ctx: \(ctx), buffer: \(buffer)")

        /// peek at messageType
        guard let messageType: Byte = buffer.peekInteger() else {
            VERBOSE("   [needMoreData: messageType=nil]")
            return .needMoreData
        }

        /// peek at messageSize
        guard let messageSize: Int32 = buffer.peekInteger(skipping: MemoryLayout<Byte>.size) else {
            // Response from a PostgreSQLSSLSupportRequest will only return a single byte, so we need to handle that case
            if (messageType == .S || messageType == .N), let data = buffer.readSlice(length: MemoryLayout<Byte>.size) {
                fatalError()
//                let message = try PostgreSQLMessage.sslSupportResponse(decoder.decode())
//                ctx.fireChannelRead(wrapInboundOut(message))
//                VERBOSE("   [message=\(message)]")
                return .continue
            } else {
                VERBOSE("   [needMoreData: messageSize=nil]")
                return .needMoreData
            }
        }

        /// ensure message is large enough or reject
        guard buffer.readableBytes - MemoryLayout<Byte>.size >= Int(messageSize) else {
            VERBOSE("   [needMoreData: readableBytes=\(buffer.readableBytes), messageSize=\(messageSize)]")
            return .needMoreData
        }

        /// skip messageType and messageSize
        buffer.moveReaderIndex(forwardBy: MemoryLayout<Byte>.size + MemoryLayout<Int32>.size)

        /// read messageData
//        guard let messageData = buffer.readSlice(length: Int(messageSize) - MemoryLayout<Int32>.size) else {
//            fatalError("buffer.readSlice returned nil even though length was checked.")
//        }

        let message: PostgreSQLMessage
        switch messageType {
//        case .A: message = try .notificationResponse(decoder.decode())
//        case .E: message = try .error(decoder.decode())
//        case .N: message = try .notice(decoder.decode())
        case .R: message = try .authenticationRequest(.parse(from: &buffer))
//        case .S: message = try .parameterStatus(decoder.decode())
        case .K: message = try .backendKeyData(.parse(from: &buffer))
//        case .Z: message = try .readyForQuery(decoder.decode())
//        case .T: message = try .rowDescription(decoder.decode())
//        case .D: message = try .dataRow(decoder.decode())
//        case .C: message = try .close(decoder.decode())
        case .one: message = .parseComplete
        case .two: message = .bindComplete
        case .n: message = .noData
//        case .t: message = try .parameterDescription(decoder.decode())
        default:
            let string = String(bytes: [messageType], encoding: .ascii) ?? "n/a"
            throw PostgreSQLError(
                identifier: "decoder",
                reason: "Unrecognized message type: \(string) (\(messageType))",
                possibleCauses: ["Connected to non-PostgreSQL database"],
                suggestedFixes: ["Connect to PostgreSQL database"]
            )
        }
        VERBOSE("   [message=\(message)]")
        ctx.fireChannelRead(wrapInboundOut(message))
        return .continue
    }

    /// Temporary
    func channelInactive(ctx: ChannelHandlerContext) {
        ctx.fireChannelInactive()
    }

    /// Called once this `ByteToMessageDecoder` is removed from the `ChannelPipeline`.
    ///
    /// - parameters:
    ///     - ctx: The `ChannelHandlerContext` which this `ByteToMessageDecoder` belongs to.
    func decoderRemoved(ctx: ChannelHandlerContext) {
        VERBOSE("PostgreSQLMessageDecoder.decoderRemoved(ctx: \(ctx))")
    }

    /// Called when this `ByteToMessageDecoder` is added to the `ChannelPipeline`.
    ///
    /// - parameters:
    ///     - ctx: The `ChannelHandlerContext` which this `ByteToMessageDecoder` belongs to.
    func decoderAdded(ctx: ChannelHandlerContext) {
        VERBOSE("PostgreSQLMessageDecoder.decoderAdded(ctx: \(ctx))")
    }
}
