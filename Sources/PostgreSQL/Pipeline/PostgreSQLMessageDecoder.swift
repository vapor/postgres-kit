import Async
import Bits
import NIO

final class PostgreSQLMessageDecoder: ByteToMessageDecoder {
    /// See `ByteToMessageDecoder.InboundOut`
    public typealias InboundOut = PostgreSQLMessage

    /// The cumulationBuffer which will be used to buffer any data.
    var cumulationBuffer: ByteBuffer?
    
    /// If `true`, the server has asked for authentication.
    var hasRequestedAuthentication: Bool
    
    /// Creates a new `PostgreSQLMessageDecoder`.
    init() {
        self.hasRequestedAuthentication = false
    }

    /// Decode from a `ByteBuffer`. This method will be called till either the input
    /// `ByteBuffer` has nothing to read left or `DecodingState.needMoreData` is returned.
    ///
    /// - parameters:
    ///     - ctx: The `ChannelHandlerContext` which this `ByteToMessageDecoder` belongs to.
    ///     - buffer: The `ByteBuffer` from which we decode.
    /// - returns: `DecodingState.continue` if we should continue calling this method or `DecodingState.needMoreData` if it should be called
    //             again once more data is present in the `ByteBuffer`.
    func decode(ctx: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        // peek at messageType
        guard let messageType: Byte = buffer.peekInteger() else {
            return .needMoreData
        }
        
        // check to see if this is a special-case ssl response
        guard hasRequestedAuthentication || buffer.readableBytes != 1 || (messageType != .N && messageType != .S) else {
            // the connection has not yet authenticated, and there is only one byte in the response,
            // this must be an SSL support response
            buffer.moveReaderIndex(forwardBy: 1)
            switch messageType {
            case .S: ctx.fireChannelRead(wrapInboundOut(.sslSupportResponse(.supported)))
            case .N: ctx.fireChannelRead(wrapInboundOut(.sslSupportResponse(.unsupported)))
            default: fatalError() // not hittable
            }
            return .continue
        }

        /// peek at message size, skipping message type.
        guard let messageSize: Int = buffer.peekInteger(skipping: 1, as: Int32.self).flatMap(numericCast) else {
            return .needMoreData
        }

        /// ensure message is large enough (skipping message type) or reject
        guard buffer.readableBytes - 1 >= Int(messageSize) else {
            return .needMoreData
        }

        // skip messageType and messageSize
        buffer.moveReaderIndex(forwardBy: 1 + 4)

        let message: PostgreSQLMessage
        switch messageType {
        case .R:
            message = try .authenticationRequest(.parse(from: &buffer))
            hasRequestedAuthentication = true
        case .K: message = try .backendKeyData(.parse(from: &buffer))
        case .two: message = .bindComplete
        case .C: message = try .close(.parse(from: &buffer))
        case .D: message = try .dataRow(.parse(from: &buffer))
        case .E: message = try .error(.parse(from: &buffer))
        case .n: message = .noData
        case .N: message = try .notice(.parse(from: &buffer))
        case .A: message = try .notification(.parse(from: &buffer))
        case .t: message = try .parameterDescription(.parse(from: &buffer))
        case .S: message = try .parameterStatus(.parse(from: &buffer))
        case .one: message = .parseComplete
        case .Z: message = try .readyForQuery(.parse(from: &buffer))
        case .T: message = try .rowDescription(.parse(from: &buffer))
        default:
            let string = String(bytes: [messageType], encoding: .ascii) ?? "n/a"
            throw PostgreSQLError(
                identifier: "decoder",
                reason: "Unrecognized message type: \(string) (\(messageType))",
                possibleCauses: ["Connected to non-PostgreSQL database"],
                suggestedFixes: ["Connect to PostgreSQL database"]
            )
        }
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
    func decoderRemoved(ctx: ChannelHandlerContext) { }

    /// Called when this `ByteToMessageDecoder` is added to the `ChannelPipeline`.
    ///
    /// - parameters:
    ///     - ctx: The `ChannelHandlerContext` which this `ByteToMessageDecoder` belongs to.
    func decoderAdded(ctx: ChannelHandlerContext) { }
}
