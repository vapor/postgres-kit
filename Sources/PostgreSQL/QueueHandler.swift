import Async
import NIO

struct InputContext<In> {
    var promise: Promise<Void>
    var onInput: (In) throws -> Bool
}

final class QueueHandler<In, Out>: ChannelInboundHandler {
    typealias InboundIn = In
    typealias OutboundOut = Out

    private var inputQueue: [InputContext<InboundIn>]
    private var outputQueue: [OutboundOut]
    private let eventLoop: EventLoop
    private var waitingCtx: ChannelHandlerContext?

    init(on worker: Worker) {
        self.inputQueue = []
        self.outputQueue = []
    }

    func enqueue(_ output: [OutboundOut], onInput: @escaping (InboundIn) throws -> Bool) -> Future<Void> {
        outputQueue.insert(contentsOf: output.reversed(), at: 0)
        let promise = eventLoop.newPromise(Void.self)
        let context = InputContext<InboundIn>(promise: promise, onInput: onInput)
        inputQueue.insert(context, at: 0)
        if let ctx = waitingCtx {
            sendOutput(ctx: ctx)
        }
        return promise.futureResult
    }

    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let input = unwrapInboundIn(data)
        guard let current = inputQueue.last else {
            assert(false, "Empty input queue.")
            return
        }
        do {
            if try current.onInput(input) {
                current.promise.succeed()
                assert(inputQueue.popLast() != nil)
            }
        } catch {
            current.promise.fail(error: error)
            assert(inputQueue.popLast() != nil)
        }
    }

    func channelActive(ctx: ChannelHandlerContext) {
        sendOutput(ctx: ctx)
    }

    func sendOutput(ctx: ChannelHandlerContext) {
        if let next = outputQueue.popLast() {
            ctx.write(wrapOutboundOut(next)).do {
                self.sendOutput(ctx: ctx)
            }.catch { error in
                fatalError("\(error)")
            }
        } else {
            waitingCtx = ctx
        }
    }
}
